//
//  validatereceipt.m
//
//  Created by Ruotger Skupin on 23.10.10.
//  Copyright 2010-2011 Matthew Stevens, Ruotger Skupin, Apple, Dave Carlton, Fraser Hess, anlumo, David Keegan. All rights reserved.
//

/*
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in
 the documentation and/or other materials provided with the distribution.

 Neither the name of the copyright holders nor the names of its contributors may be used to endorse or promote products derived
 from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
 BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "validatereceipt.h"

// link with Foundation.framework, IOKit.framework, Security.framework and libCrypto (via -lcrypto in Other Linker Flags)

#import <IOKit/IOKitLib.h>
#import <Foundation/Foundation.h>

#import <Security/Security.h>

#include <openssl/pkcs7.h>
#include <openssl/objects.h>
#include <openssl/sha.h>
#include <openssl/x509.h>
#include <openssl/err.h>

//#define USE_SAMPLE_RECEIPT // also defined in the debug build settings

#ifdef USE_SAMPLE_RECEIPT
#warning ************************************
#warning ******* USES SAMPLE RECEIPT! *******
#warning ************************************
#endif

#define VRCFRelease(object) if(object) CFRelease(object)

NSString *kReceiptBundleIdentifier = @"BundleIdentifier";
NSString *kReceiptBundleIdentifierData = @"BundleIdentifierData";
NSString *kReceiptVersion = @"Version";
NSString *kReceiptOpaqueValue = @"OpaqueValue";
NSString *kReceiptHash = @"Hash";


NSData * appleRootCert(void)
{
	OSStatus status;

	SecKeychainRef keychain = nil;
	status = SecKeychainOpen("/System/Library/Keychains/SystemRootCertificates.keychain", &keychain);
	if(status){
		VRCFRelease(keychain);
		return nil;
	}

	CFArrayRef searchList = CFArrayCreate(kCFAllocatorDefault, (const void**)&keychain, 1, &kCFTypeArrayCallBacks);

	// For some reason we get a malloc reference underflow warning message when garbage collection
	// is on. Perhaps a bug in SecKeychainOpen where the keychain reference isn't actually retained
	// in GC?
#ifndef __OBJC_GC__
	VRCFRelease(keychain);
#endif

	SecKeychainSearchRef searchRef = nil;
	status = SecKeychainSearchCreateFromAttributes(searchList, kSecCertificateItemClass, NULL, &searchRef);
	if(status){
		VRCFRelease(searchRef);
		VRCFRelease(searchList);
		return nil;
	}

	SecKeychainItemRef itemRef = nil;
	NSData * resultData = nil;

	while(SecKeychainSearchCopyNext(searchRef, &itemRef) == noErr && resultData == nil) {
		// Grab the name of the certificate
		SecKeychainAttributeList list;
		SecKeychainAttribute attributes[1];

		attributes[0].tag = kSecLabelItemAttr;

		list.count = 1;
		list.attr = attributes;

		SecKeychainItemCopyContent(itemRef, nil, &list, nil, nil);
		NSData *nameData = [NSData dataWithBytesNoCopy:attributes[0].data length:attributes[0].length freeWhenDone:NO];
		NSString *name = [[NSString alloc] initWithData:nameData encoding:NSUTF8StringEncoding];

		if([name isEqualToString:@"Apple Root CA"]) {
			CSSM_DATA certData;
			SecCertificateGetData((SecCertificateRef)itemRef, &certData);
			resultData = [NSData dataWithBytes:certData.Data length:certData.Length];
		}
		
		SecKeychainItemFreeContent(&list, NULL);

		if (itemRef)
			VRCFRelease(itemRef);

		[name release];
	}

	VRCFRelease(searchList);
	VRCFRelease(searchRef);

	return resultData;
}


NSDictionary * dictionaryWithAppStoreReceipt(NSString * path)
{
	NSData * rootCertData = appleRootCert();

	enum ATTRIBUTES
	{
		ATTR_START = 1,
		BUNDLE_ID,
		VERSION,
		OPAQUE_VALUE,
		HASH,
		ATTR_END
	};

	ERR_load_PKCS7_strings();
	ERR_load_X509_strings();
	OpenSSL_add_all_digests();

	// Expected input is a PKCS7 container with signed data containing
	// an ASN.1 SET of SEQUENCE structures. Each SEQUENCE contains
	// two INTEGERS and an OCTET STRING.

	const char * receiptPath = [[path stringByStandardizingPath] fileSystemRepresentation];
	FILE *fp = fopen(receiptPath, "rb");
	if (fp == NULL)
		return nil;

	PKCS7 *p7 = d2i_PKCS7_fp(fp, NULL);
	fclose(fp);

	// Check if the receipt file was invalid (otherwise we go crashing and burning)
	if (p7 == NULL) {
		return nil;
	}

	if (!PKCS7_type_is_signed(p7)) {
		PKCS7_free(p7);
		return nil;
	}

	if (!PKCS7_type_is_data(p7->d.sign->contents)) {
		PKCS7_free(p7);
		return nil;
	}

	int verifyReturnValue = 0;
	X509_STORE *store = X509_STORE_new();
	if (store)
	{
		const unsigned char *data = (unsigned char *)(rootCertData.bytes);
		X509 *appleCA = d2i_X509(NULL, &data, (long)rootCertData.length);
		if (appleCA)
		{
			BIO *payload = BIO_new(BIO_s_mem());
			X509_STORE_add_cert(store, appleCA);

			if (payload)
			{
				verifyReturnValue = PKCS7_verify(p7,NULL,store,NULL,payload,0);
				BIO_free(payload);
			}

			// this code will come handy when the first real receipts arrive
#if 0
			unsigned long err = ERR_get_error();
			if(err)
				printf("%lu: %s\n",err,ERR_error_string(err,NULL));
			else {
				STACK_OF(X509) *stack = PKCS7_get0_signers(p7, NULL, 0);
				for(NSUInteger i = 0; i < sk_num(stack); i++) {
					const X509 *signer = (X509*)sk_value(stack, i);
					NSLog(@"name = %s", signer->name);
				}
			}
#endif

			X509_free(appleCA);
		}
		X509_STORE_free(store);
	}
	EVP_cleanup();

	if (verifyReturnValue != 1)
	{
		PKCS7_free(p7);
		return nil;
	}

	ASN1_OCTET_STRING *octets = p7->d.sign->contents->d.data;
	const unsigned char *p = octets->data;
	const unsigned char *end = p + octets->length;

	int type = 0;
	int xclass = 0;
	long length = 0;

	ASN1_get_object(&p, &length, &type, &xclass, end - p);
	if (type != V_ASN1_SET) {
		PKCS7_free(p7);
		return nil;
	}

	NSMutableDictionary *info = [NSMutableDictionary dictionary];

	while (p < end) {
		ASN1_get_object(&p, &length, &type, &xclass, end - p);
		if (type != V_ASN1_SEQUENCE)
			break;

		const unsigned char *seq_end = p + length;

		int attr_type = 0;
		int attr_version = 0;

		// Attribute type
		ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
		if (type == V_ASN1_INTEGER && length == 1) {
			attr_type = p[0];
		}
		p += length;

		// Attribute version
		ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
		if (type == V_ASN1_INTEGER && length == 1) {
			attr_version = p[0];
			attr_version = attr_version;
		}
		p += length;

		// Only parse attributes we're interested in
		if (attr_type > ATTR_START && attr_type < ATTR_END) {
			NSString *key = nil;

			ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
			if (type == V_ASN1_OCTET_STRING) {
                NSData *data = [NSData dataWithBytes:p length:(NSUInteger)length];
                
				// Bytes
				if (attr_type == BUNDLE_ID || attr_type == OPAQUE_VALUE || attr_type == HASH) {
					switch (attr_type) {
						case BUNDLE_ID:
							// This is included for hash generation
							key = kReceiptBundleIdentifierData;
							break;
						case OPAQUE_VALUE:
							key = kReceiptOpaqueValue;
							break;
						case HASH:
							key = kReceiptHash;
							break;
					}
					if (key) {
                        [info setObject:data forKey:key];
                    }
				}

				// Strings
				if (attr_type == BUNDLE_ID || attr_type == VERSION) {
					int str_type = 0;
					long str_length = 0;
					const unsigned char *str_p = p;
					ASN1_get_object(&str_p, &str_length, &str_type, &xclass, seq_end - str_p);
					if (str_type == V_ASN1_UTF8STRING) {
						switch (attr_type) {
							case BUNDLE_ID:
								key = kReceiptBundleIdentifier;
								break;
							case VERSION:
								key = kReceiptVersion;
								break;
						}
                        
						if (key) {                        
                            NSString *string = [[NSString alloc] initWithBytes:str_p
																		length:(NSUInteger)str_length
                                                                      encoding:NSUTF8StringEncoding];
                            [info setObject:string forKey:key];
                            [string release];
						}
					}
				}
			}
			p += length;
		}

		// Skip any remaining fields in this SEQUENCE
		while (p < seq_end) {
			ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
			p += length;
		}
	}

	PKCS7_free(p7);

	return info;
}



// Returns a CFData object, containing the machine's GUID.
CFDataRef copy_mac_address(void)
{
	kern_return_t			 kernResult;
	mach_port_t			   master_port;
	CFMutableDictionaryRef	matchingDict;
	io_iterator_t			 iterator;
	io_object_t			   service;
	CFDataRef				 macAddress = nil;

	kernResult = IOMasterPort(MACH_PORT_NULL, &master_port);
	if (kernResult != KERN_SUCCESS) {
		printf("IOMasterPort returned %d\n", kernResult);
		return nil;
	}

	matchingDict = IOBSDNameMatching(master_port, 0, "en0");
	if(!matchingDict) {
		printf("IOBSDNameMatching returned empty dictionary\n");
		return nil;
	}

	kernResult = IOServiceGetMatchingServices(master_port, matchingDict, &iterator);
	if (kernResult != KERN_SUCCESS) {
		printf("IOServiceGetMatchingServices returned %d\n", kernResult);
		return nil;
	}

	while((service = IOIteratorNext(iterator)) != 0)
	{
		io_object_t		parentService;

		kernResult = IORegistryEntryGetParentEntry(service, kIOServicePlane, &parentService);
		if(kernResult == KERN_SUCCESS)
		{
			VRCFRelease(macAddress);
			macAddress = IORegistryEntryCreateCFProperty(parentService, CFSTR("IOMACAddress"), kCFAllocatorDefault, 0);
			IOObjectRelease(parentService);
		}
		else {
			printf("IORegistryEntryGetParentEntry returned %d\n", kernResult);
		}

		IOObjectRelease(service);
	}

	return macAddress;
}

extern const NSString * global_bundleVersion;
extern const NSString * global_bundleIdentifier;

// in your project define those two somewhere as such:
// const NSString * global_bundleVersion = @"1.0.2";
// const NSString * global_bundleIdentifier = @"com.example.SampleApp";

BOOL validateReceiptAtPath(NSString * path)
{
	// it turns out, it's a bad idea, to use these two NSBundle methods in your app:
	//
	// bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	// bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
	//
	// http://www.craftymind.com/2011/01/06/mac-app-store-hacked-how-developers-can-better-protect-themselves/
	//
	// so use hard coded values instead (probably even somehow obfuscated)

	// analyser warning when USE_SAMPLE_RECEIPT is defined (wontfix)
	NSString *bundleVersion = (NSString*)global_bundleVersion;
	NSString *bundleIdentifier = (NSString*)global_bundleIdentifier;
#ifndef USE_SAMPLE_RECEIPT
  //  NSLog(@"%@", bundleVersion);
  //  NSLog(@"%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]);
  //  NSLog(@"%@", bundleIdentifier);
  //  NSLog(@"%@", [[NSBundle mainBundle] bundleIdentifier]);
	// avoid making stupid mistakes --> check again
	NSCAssert([bundleVersion isEqualToString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]],
			 @"whoops! check the hard-coded CFBundleShortVersionString!");
	NSCAssert([bundleIdentifier isEqualToString:[[NSBundle mainBundle] bundleIdentifier]],
			 @"whoops! check the hard-coded bundle identifier!");
#else
	bundleVersion = @"1.0.2";
	bundleIdentifier = @"com.example.SampleApp";
#endif
	NSDictionary * receipt = dictionaryWithAppStoreReceipt(path);

	if (!receipt)
		return NO;

	NSData * guidData = nil;
#ifndef USE_SAMPLE_RECEIPT
	guidData = (NSData*)copy_mac_address();

	if ([NSGarbageCollector defaultCollector])
		[[NSGarbageCollector defaultCollector] enableCollectorForPointer:guidData];
	else
		[guidData autorelease];

	if (!guidData)
		return NO;
#else
	// Overwrite with example GUID for use with example receipt
	unsigned char guid[] = { 0x00, 0x17, 0xf2, 0xc4, 0xbc, 0xc0 };
	guidData = [NSData dataWithBytes:guid length:sizeof(guid)];
#endif

	NSMutableData *input = [NSMutableData data];
	[input appendData:guidData];
	[input appendData:[receipt objectForKey:kReceiptOpaqueValue]];
	[input appendData:[receipt objectForKey:kReceiptBundleIdentifierData]];

	NSMutableData *hash = [NSMutableData dataWithLength:SHA_DIGEST_LENGTH];
	SHA1([input bytes], [input length], [hash mutableBytes]);

	if ([bundleIdentifier isEqualToString:[receipt objectForKey:kReceiptBundleIdentifier]] &&
		 [bundleVersion isEqualToString:[receipt objectForKey:kReceiptVersion]] &&
		 [hash isEqualToData:[receipt objectForKey:kReceiptHash]])
	{
		return YES;
	}

	return NO;
}
