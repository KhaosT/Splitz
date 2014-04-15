//
//  OTIWrapperCore.m
//  Wrapper
//
//  Created by Khaos Tian on 4/11/14.
//  Copyright (c) 2014 Oltica. All rights reserved.
//

#import "OTIWrapperCore.h"
#import "OTILEManager.h"
#import "OTIHashing.h"
#import <AddressBook/AddressBook.h>

@interface OTIWrapperCore (){
    OTILEManager *_leManager;
    
    NSMutableDictionary *_contacts;
}

@end

@implementation OTIWrapperCore

+ (OTIWrapperCore *)sharedCore
{
    static OTIWrapperCore *wrapperCore = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        wrapperCore = [[self alloc]init];
    });
    
    return wrapperCore;
}

- (id)init
{
    if (self = [super init]) {
        _leManager = [[OTILEManager alloc]init];
        [_leManager initPeripheralManager];
        [_leManager initCentalManager];
        
        _contacts = [[NSMutableDictionary alloc]init];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self constructContacts];
        });
    }
    return self;
}

- (void)constructContacts
{
    ABAddressBookRequestAccessWithCompletion(ABAddressBookCreateWithOptions(NULL, nil), ^(bool granted, CFErrorRef error) {
        if (granted) {
            ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, nil);
            
            NSArray *allContacts = (__bridge NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBookRef);
            
            for (id record in allContacts){
                ABRecordRef thisContact = (__bridge ABRecordRef)record;
                
                NSString *name = (__bridge NSString *)(ABRecordCopyCompositeName(thisContact));
                
                ABMultiValueRef emailMultiValue = ABRecordCopyValue(thisContact, kABPersonEmailProperty);
                NSArray *emailAddresses = (__bridge NSArray *)ABMultiValueCopyArrayOfAllValues(emailMultiValue);
                CFRelease(emailMultiValue);
                
                UIImage *avatar = nil;
                
                if (ABPersonHasImageData(thisContact)) {
                    avatar = [UIImage imageWithData:(__bridge NSData *)ABPersonCopyImageDataWithFormat(thisContact, kABPersonImageFormatThumbnail)];
                }
                
                for (NSString *email in emailAddresses) {
                    if (name && email) {
                        NSString *lowerUserName = [email lowercaseString];
                        if (avatar) {
                            [_contacts setObject:@{@"name": name,@"email": lowerUserName,@"avatar":avatar} forKey:[OTIHashing hashValueForString:lowerUserName]];
                        }else{
                            [_contacts setObject:@{@"name": name,@"email": lowerUserName} forKey:[OTIHashing hashValueForString:lowerUserName]];
                        }
                    }
                }
            }
        }
    });
}

- (void)dataSourceDidUpdated
{
    if (_dataNotifier && [_dataNotifier respondsToSelector:@selector(updateData:)]) {
        [_dataNotifier updateData:self];
    }
}

- (NSDictionary *)userContacts
{
    return [_contacts copy];
}

- (NSArray *)peersAround
{
    return [_leManager peersAround];
}

@end
