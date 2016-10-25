//
//  DataManager.h
//  
//
//  Created by code-on on 4/3/15.
//  Copyright (c) 2015 code-on. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SKDatabase.h"

typedef void(^DBMasterSuccessBlock)(BOOL responseData);
typedef void(^DBMasterFailureBlock)(BOOL responseData);


@interface DataManager : NSObject{
}
+ (DataManager *)shareddbSingleton;

-(void)AddPublicProject :(NSDictionary *)dict;
-(void)Addscenes:(int)slideId :(NSString *)slideData;
-(NSArray *)GetScnes;
-(void)Adddownloadables:(NSString *)URL :(NSString *)type;

-(void)Downloaded:(NSString *)URL;
-(NSArray *)GetScnesFromID:(NSString *)slideId;
-(NSString *)ConvertUrl:(NSString *)url :(NSString *)pin_Id;

-(NSArray *)GetDownloadPublic;
-(NSArray *)GetDownloadPin;
@end
