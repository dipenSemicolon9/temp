//
//  DataManager.m
//  IdeaManagemenet
//
//  Created by code-on on 4/3/15.
//  Copyright (c) 2015 code-on. All rights reserved.
//

/*
 Notes:
 is_publish 
 = 0 =>Not sync
 = 1 =>sync with server
 */

#import "DataManager.h"
#import "ScenesShare.h"
@implementation DataManager
static DataManager *singletonObj = NULL;
static SKDatabase *db = NULL;

+ (DataManager *)shareddbSingleton {
    @synchronized(self) {
        if (singletonObj == NULL)
            singletonObj = [[self alloc] init];
            db=[[SKDatabase alloc]initWithFile:@"studets.db"];
    }
    return(singletonObj);
}

-(void)AddPublicProject :(NSDictionary *)dict{
    NSMutableDictionary *tempdict = [dict mutableCopy];
    [tempdict setValue:[NSString stringWithFormat:@"%@",[[dict valueForKey:@"id"] stringValue]] forKey:@"id"];
    [db insertDictionary:tempdict forTable:@"publicProjects"];
}

-(void)Addscenes:(int)slideId :(NSString *)slideData{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:[NSString stringWithFormat:@"%d",slideId] forKey:@"slideId"];
    [dict setValue:slideData forKey:@"slideData"];
    [db insertDictionary:dict forTable:@"scenes"];
    
}

-(void)Adddownloadables:(NSString *)URL :(NSString *)type{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:URL forKey:@"URL"];
    [dict setValue:@"0" forKey:@"isDownload"];
    [dict setValue:type forKey:@"type"];
    [db insertDictionary:dict forTable:@"downloadables"];
    
}


-(NSArray *)GetScnes{
    
    NSString *qry = @"select * from scenes";
    NSMutableArray *ary = [[NSMutableArray alloc] init];
    
    for (NSDictionary *dict in [db lookupAllForSQL:qry]) {
        ScenesShare *shareobj = [[ScenesShare alloc] init];
        shareobj.slideId = [[dict valueForKey:@"slideId"] intValue];
        shareobj.slideData = [dict valueForKey:@"slideData"];
        /*NSString *jsonString = [dict valueForKey:@"slideData"];
        NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        shareobj.slideData = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        */[ary addObject:shareobj];
    }
    return ary;
    
}

-(NSArray *)GetScnesFromID:(NSString *)slideId{
    NSString *qry = [NSString stringWithFormat:@"select * from scenes where slideId='%@' limit 0,1",slideId];
    NSMutableArray *ary = [[NSMutableArray alloc] init];
    
    for (NSDictionary *dict in [db lookupAllForSQL:qry]) {
        ScenesShare *shareobj = [[ScenesShare alloc] init];
        shareobj.slideId = [[dict valueForKey:@"slideId"] intValue];
        shareobj.slideData = [dict valueForKey:@"slideData"];
//        NSString *jsonString = [dict valueForKey:@"slideData"];
//        NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
//        shareobj.slideData = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        [ary addObject:shareobj];
    }
    return ary;
    
}

-(NSArray *)GetDownloadPin{
    NSString *qry = @"select * from downloadables where isDownload='0' and type = 'pin' limit 0,1";
    return [db lookupAllForSQL:qry];
}

-(NSArray *)GetDownloadPublic{
    NSString *qry = @"select * from downloadables where isDownload='0' and type = 'public' limit 0,1";
    return [db lookupAllForSQL:qry];
}


-(void)Downloaded:(NSString *)URL{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setValue:@"1" forKey:@"isDownload"];
    [db updateDictionary:dict forTable:@"downloadables" where:[NSString stringWithFormat:@"URL = '%@'",URL]];
}

-(NSString *)ConvertUrl:(NSString *)url :(NSString *)pin_Id{

    //splite file name form url
    NSArray *parts = [url componentsSeparatedByString:@"/"];
    NSString *filename = [parts lastObject];
  
    //get document directory path
    NSString *documentsDirectory = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    documentsDirectory = [paths objectAtIndex:0];
    NSString *checkdataPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@/%@",pin_Id,filename]];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:checkdataPath];
    if (fileExists) {
        return  checkdataPath;
    }else{
        return  @"";
    }
    
}

@end
