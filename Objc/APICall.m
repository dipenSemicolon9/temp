//
//  APICall.m
//  VROBJC
//
//  Created by tasol on 9/16/16.
//  Copyright © 2016 tasol. All rights reserved.
//

#import "APICall.h"
#import "DataManager.h"

@implementation APICall
@synthesize docDir;
#define g_BaseURL @"http://192.168.5.151:8000/API/v1"
#define g_Download_BaseURL @"http://192.168.5.151:8000"


-(id) init {
    self = [super init];
    if (self) {
        docDir = [self getDocumentDir];
    }
    return(self);
}


-(NSString *)getDocumentDir{
    NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docdir = [docPaths objectAtIndex:0];
    return docdir;
}

-(void)StartDownloadPublic{
    
    NSArray *ary = [[DataManager shareddbSingleton] GetDownloadPublic];
    if(ary.count >= 1){
        //start download.
        NSDictionary *dict = [ary objectAtIndex:0];
        NSString *url = [dict valueForKey:@"URL"];
        NSString *theFileName = [url lastPathComponent] ;
        NSString *extension = [theFileName pathExtension];
        if([extension isEqualToString:@"png"] || [extension isEqualToString:@"jpg"]){
            
            [self downloadImage:url :@"public":theFileName  success:^(id responseData) {
                NSDictionary *resDict = (NSDictionary *)responseData;
                [[DataManager shareddbSingleton] Downloaded:[resDict valueForKey:@"URL"]];
                [self StartDownloadPublic];
            }];
            
        }else{
            [self downloadVideo:url :@"public" :theFileName  success:^(id responseData) {
                NSDictionary *resDict = (NSDictionary *)responseData;
                [[DataManager shareddbSingleton] Downloaded:[resDict valueForKey:@"URL"]];
                [self StartDownloadPublic];
            }];
        }
    }else{
        NSLog(@"Downloaded All Files");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadPublicDone" object:nil];
    }
}

-(void)StartDownload:(NSString *)pin_id{
    
    NSArray *ary = [[DataManager shareddbSingleton] GetDownloadPin];
    NSLog(@"DownloadArray:%@",ary);
    if(ary.count >= 1){
        //start download.
        NSDictionary *dict = [ary objectAtIndex:0];
        NSString *url = [dict valueForKey:@"URL"];
        NSString *theFileName = [url lastPathComponent] ;
        NSString *extension = [theFileName pathExtension];
        if([extension isEqualToString:@"png"] || [extension isEqualToString:@"jpg"]){
            [self downloadImage:url :pin_id:theFileName  success:^(id responseData) {
                NSDictionary *resDict = (NSDictionary *)responseData;
                [[DataManager shareddbSingleton] Downloaded:[resDict valueForKey:@"URL"]];
                [self StartDownload:pin_id];
            }];
            
        }else{
            [self downloadVideo:url :pin_id :theFileName  success:^(id responseData) {
                NSDictionary *resDict = (NSDictionary *)responseData;
                [[DataManager shareddbSingleton] Downloaded:[resDict valueForKey:@"URL"]];
                [self StartDownload:pin_id];
            }];
        }
    }else{
        NSLog(@"Downloaded All Files");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadAllDone" object:nil];
    }
}

-(void)CallPublicProject:(NSString *)url
                 success:(WebMasterSuccessBlock)successBlock
                 Failure:(WebMasterSuccessBlock)failureBlock{
    NSLog(@"Public:URL:%@",url);
    
    NSString *newUrl = [NSString stringWithFormat:@"%@/%@",g_BaseURL,url];
    [self baseWscalldispatch:nil :newUrl success:^(id responseData) {
        NSArray *aryPublic = [responseData valueForKey:@"publicProjects"];
        NSLog(@"Ary:%@",aryPublic);
        NSString *documentsDirectory = nil;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        documentsDirectory = [paths objectAtIndex:0];
        NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"public"]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]){
            [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:YES attributes:nil error:nil];
            
        }
        
        for (NSDictionary *dict in aryPublic) {
            [[DataManager shareddbSingleton] AddPublicProject:dict];
            [[DataManager shareddbSingleton] Adddownloadables:[dict valueForKey:@"thumb_url"] :@"public"];
        }
        
         successBlock(responseData);
    } Failure:^(id responseData) {
        failureBlock(responseData);
    }];
    
}

-(void)CallPinIdAPI:(NSMutableDictionary *)params :(NSString *)fileNameURL
            success:(WebMasterSuccessBlock)successBlock
            Failure:(WebMasterSuccessBlock)failureBlock{
    
    NSString *pin_id = [params valueForKey:@"pin_id"];
    NSString *timestamp = [params valueForKey:@"timestamp"];
    NSString *videoType = [params valueForKey:@"videoType"];
    NSString *newUrl = [NSString stringWithFormat:@"%@/%@/%@/%@",g_BaseURL,pin_id,timestamp,videoType];
    
    [self baseWscalldispatch:nil :newUrl success:^(id responseData) {
        
        NSString *timestamp = [responseData valueForKey:@"timestamp"] ;
        NSDictionary *globalsettings = [responseData valueForKey:@"globalsettings"] ;
        
        //store timestamp to nsuserdefault
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setValue:timestamp forKey:@"timestamp"];
        [defaults setValue:[self convertJsonToString:globalsettings] forKey:@"globalsettings"];
        
        [defaults synchronize];
        NSArray *scenes = [responseData valueForKey:@"scenes"];
        
        NSString *documentsDirectory = nil;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        documentsDirectory = [paths objectAtIndex:0];
        NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@",pin_id]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]){
            [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:YES attributes:nil error:nil];
            
        }
        
        //insert scenes
        for (NSDictionary *dict in scenes) {
            int slideId = [[dict valueForKey:@"slideId"] intValue];
            NSArray *myArray = [dict valueForKey:@"slideData"];
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:myArray options:NSJSONWritingPrettyPrinted error:nil];
            NSString *slideData = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            [[DataManager shareddbSingleton] Addscenes:slideId :slideData];
        }
        
        //Insert Downlables data
        NSArray *downloadables = [responseData valueForKey:@"downloadables"];
        
        //insert scenes
        for (NSString *URL in downloadables) {
            [[DataManager shareddbSingleton] Adddownloadables:[NSString stringWithFormat:@"%@%@",g_Download_BaseURL,URL] :@"pin"];
        }
        successBlock(responseData);
        
    } Failure:^(id responseData) {
         failureBlock(responseData);
    }];
}


-(void)baseWscalldispatch:(NSMutableDictionary *)params :(NSString *)newUrl
                  success:(WebMasterSuccessBlock)successBlock
                  Failure:(WebMasterSuccessBlock)failureBlock{
    
    NSURL *url = [NSURL URLWithString:newUrl];
    NSLog(@"URL:%@",url);
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         if(error == nil){
           
             NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
             NSLog(@"%@",dictionary);
             NSString *code;
             
             if([[dictionary valueForKey:@"code"] isKindOfClass:[NSNumber class]]){
                 code = [NSString stringWithFormat:@"%@",[[dictionary valueForKey:@"code"] stringValue]];
             }else{
                 code = [dictionary valueForKey:@"code"];
             }
             
             if([code isEqualToString:@"200"] ){
                 successBlock(dictionary);
             }else{
                 failureBlock(dictionary);
             }
         }else{
             NSLog(@"%@",error);
             failureBlock(error);
         }
     }];
    
}

-(void) downloadImage :(NSString *)url :(NSString *)pin_id :(NSString *)guideName  success:(WebMasterSuccessBlock)successBlock{
    
    // Get dir
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *pathString = [NSString stringWithFormat:@"%@/%@/%@",documentsDirectory,pin_id,guideName];
    NSLog(@"%@",pathString);
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:pathString];
    if (fileExists) {
        NSMutableDictionary *dict  = [[NSMutableDictionary alloc] init];
        [dict setValue:url forKey:@"URL"];
        successBlock(dict);
    }else{
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue new] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            if (connectionError)
            {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    NSLog(@"Error occurred: %@", connectionError.localizedDescription);
                }];
            }
            else
            {
                UIImage *image = [[UIImage alloc] initWithData:data];
                // NSLog(@"%@",pathString);
                // Save Image
                NSString *extension = [guideName pathExtension];
                NSData *imageData;
                if([extension isEqualToString:@"jpg"]){
                    imageData = UIImageJPEGRepresentation(image, 90);
                    
                }else if([extension isEqualToString:@"png"]){
                    imageData = UIImagePNGRepresentation(image);;
                    
                }
                
                [imageData writeToFile:pathString atomically:YES];
                NSMutableDictionary *dict  = [[NSMutableDictionary alloc] init];
                [dict setValue:url forKey:@"URL"];
                
                successBlock(dict);
                
            }
        }];
    }
    
}

-(void) downloadVideo :(NSString *)url :(NSString *)pin_id :(NSString *)guideName  success:(WebMasterSuccessBlock)successBlock{
    
    // Get dir
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *pathString = [NSString stringWithFormat:@"%@/%@/%@",documentsDirectory,pin_id,guideName];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:pathString];
    if (fileExists) {
        NSMutableDictionary *dict  = [[NSMutableDictionary alloc] init];
        [dict setValue:url forKey:@"URL"];
        successBlock(dict);
    }else{
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue new] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            if (connectionError)
            {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    NSLog(@"Error occurred: %@", connectionError.localizedDescription);
                }];
            }
            else
            {
                [data writeToFile:pathString atomically:YES];
                NSMutableDictionary *dict  = [[NSMutableDictionary alloc] init];
                [dict setValue:url forKey:@"URL"];
                successBlock(dict);
            }
        }];
    }
    
}

-(NSString *)convertJsonToString:(id)jsonObject{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted error:nil];
    NSString *slideData = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return  slideData;
}

-(id)convertStringToJson:(NSString *)jsonstring{
    NSError *jsonError;
    NSData *objectData = [jsonstring dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization JSONObjectWithData:objectData
                                           options:NSJSONReadingMutableContainers
                                             error:&jsonError];
}



@end
