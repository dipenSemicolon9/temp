//
//  APICall.h
//  VROBJC
//
//  Created by tasol on 9/16/16.
//  Copyright © 2016 tasol. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^WebMasterSuccessBlock)(id responseData);
typedef void(^WebMasterFailureBlock)(id responseData);
typedef void(^WebMasterProgressBlock)(float responseData);

@interface APICall : NSObject

@property(nonatomic,retain)NSString *docDir;
-(void)baseWscalldispatch:(NSMutableDictionary *)params :(NSString *)fileNameURL
                  success:(WebMasterSuccessBlock)successBlock
                  Failure:(WebMasterSuccessBlock)failureBlock;

-(void)StartDownloadPublic;
-(void)StartDownload:(NSString *)pin_id;

-(void)CallPublicProject:(NSString *)url
                 success:(WebMasterSuccessBlock)successBlock
                 Failure:(WebMasterSuccessBlock)failureBlock;

-(void)CallPinIdAPI:(NSMutableDictionary *)params :(NSString *)fileNameURL
            success:(WebMasterSuccessBlock)successBlock
            Failure:(WebMasterSuccessBlock)failureBlock;
-(NSString *)convertJsonToString:(id)jsonObject;
-(id)convertStringToJson:(NSString *)jsonstring;
@end
