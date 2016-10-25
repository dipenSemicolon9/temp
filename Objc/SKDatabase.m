// Copyright 2011 Jason Whitehorn
// Released under the terms of the license found
// in the license.txt in the root of the project

// Based on works originally found @
// http://iphoneinaction.manning.com/iphone_in_action/2009/07/skdatabase-11-a-sqlite-library-for-the-iphone.html
// Unfortunantly that website is no longer around.
// If memory serves me correctly the original author
// released it into the public domain.

#import "SKDatabase.h"

@implementation SKDatabase

@synthesize delegate;
@synthesize dbh;
@synthesize dynamic;

// Two ways to init: one if you're just SELECTing from a database, one if you're UPDATing
// and or INSERTing

- (id)initWithReadOnlyFile:(NSString *)dbFile {
    if (self = [super init]) {
        
        NSString *paths = [[NSBundle mainBundle] resourcePath];
        NSString *path = [paths stringByAppendingPathComponent:dbFile];
        NSLog(@"Opening database %@", path);
        
        int result = sqlite3_open([path UTF8String], &dbh);
        NSAssert1(SQLITE_OK == result, NSLocalizedStringFromTable(@"Unable to open the sqlite database (%@).", @"Database", @""), [NSString stringWithUTF8String:sqlite3_errmsg(dbh)]);
        self.dynamic = NO;
    }
    
    return self;
}

- (id)initWithFile:(NSString *)dbFile {
    if (self = [super init]) {
        
        NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docDir = [docPaths objectAtIndex:0];
        NSString *docPath = [docDir stringByAppendingPathComponent:dbFile];
        
        NSLog(@"DBPATH:%@",docPath);
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if (![fileManager fileExistsAtPath:docPath]) {
            
            //sqlite3* db = NULL;
            int rc=0;
            
            NSString *filePath = [self getDbFilePath];
            NSLog(@"DBPAT:%@",filePath);
            rc = sqlite3_open_v2([filePath cStringUsingEncoding:NSUTF8StringEncoding], &dbh, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL);
            if (SQLITE_OK != rc)
            {
                sqlite3_close(dbh);
                NSLog(@"Failed to open db connection");
            }
            else
            {
                char * query ="CREATE TABLE IF NOT EXISTS scenes (slideId INTEGER PRIMARY KEY , slideData  TEXT)";
                char * errMsg;
                rc = sqlite3_exec(dbh, query,NULL,NULL,&errMsg);
                

                char * downloadablesquery ="CREATE TABLE IF NOT EXISTS downloadables (URL TEXT PRIMARY KEY, isDownload TEXT, type TEXT)";
                char * downloadableserrMsg;
                rc = sqlite3_exec(dbh, downloadablesquery,NULL,NULL,&downloadableserrMsg);

                char * publicquery ="CREATE TABLE IF NOT EXISTS publicProjects (id TEXT PRIMARY KEY, name TEXT, description TEXT, token TEXT, created_by TEXT, thumb_url TEXT)";
                char * publicqueryerrMsg;
                rc = sqlite3_exec(dbh, publicquery,NULL,NULL,&publicqueryerrMsg);
                
                if(SQLITE_OK != rc)
                {
                    NSLog(@"Failed to create table rc:%d, msg=%s",rc,errMsg);
                }
                
               // sqlite3_close(db);
            }

        }
        int result = sqlite3_open([docPath UTF8String], &dbh);
        
        
        NSAssert1(SQLITE_OK == result, NSLocalizedStringFromTable(@"Unable to open the sqlite database (%@).", @"Database", @""), [NSString stringWithUTF8String:sqlite3_errmsg(dbh)]);
        self.dynamic = YES;
    }
    
    return self;
}

- (id)initWithData:(NSData *)data andFile:(NSString *)dbFile {
    if (self = [super init]) {
        
        NSArray *docPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docDir = [docPaths objectAtIndex:0];
        NSString *docPath = [docDir stringByAppendingPathComponent:dbFile];
        bool success = [data writeToFile:docPath atomically:YES];
        
        NSAssert1(success,[NSString stringWithString:@"Failed to save database into documents path"], nil);
        
        int result = sqlite3_open([docPath UTF8String], &dbh);
        NSAssert1(SQLITE_OK == result, NSLocalizedStringFromTable(@"Unable to open the sqlite database (%@).", @"Database", @""), [NSString stringWithUTF8String:sqlite3_errmsg(dbh)]);
        self.dynamic = YES;
    }
    
    return self;
}

// Users should never need to call prepare

- (sqlite3_stmt *)prepare:(NSString *)sql {
    
    const char *utfsql = [sql UTF8String];
    
    sqlite3_stmt *statement;
    
    if (sqlite3_prepare([self dbh],utfsql,-1,&statement,NULL) == SQLITE_OK) {
        return statement;
    } else {
        return 0;
    }
}

// Three ways to lookup results: for a variable number of responses, for a full row
// of responses, or for a singular bit of data

- (NSArray *)lookupAllForSQL:(NSString *)sql {
    sqlite3_stmt *statement;
    id result;
    NSMutableArray *thisArray = [NSMutableArray arrayWithCapacity:4];
    statement = [self prepare:sql];
    if (statement) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            NSMutableDictionary *thisDict = [NSMutableDictionary dictionaryWithCapacity:4];
            for (int i = 0 ; i < sqlite3_column_count(statement) ; i++) {
                if(sqlite3_column_type(statement,i) == SQLITE_NULL){
                    continue;
                }
                if (sqlite3_column_decltype(statement,i) != NULL &&
                    strcasecmp(sqlite3_column_decltype(statement,i),"Boolean") == 0) {
                    result = [NSNumber numberWithBool:(BOOL)sqlite3_column_int(statement,i)];
                } else if (sqlite3_column_type(statement,i) == SQLITE_INTEGER) {
                    result = [NSNumber numberWithInt:(int)sqlite3_column_int(statement,i)];
                } else if (sqlite3_column_type(statement,i) == SQLITE_FLOAT) {
                    result = [NSNumber numberWithFloat:(float)sqlite3_column_double(statement,i)];
                } else {
                    if((char *)sqlite3_column_text(statement,i) != NULL){
                        result = [[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(statement,i)];
                        [thisDict setObject:result
                                     forKey:[NSString stringWithUTF8String:sqlite3_column_name(statement,i)]];
                        //[result release];
                        result = nil;
                    }
                }
                if (result) {
                    [thisDict setObject:result
                                 forKey:[NSString stringWithUTF8String:sqlite3_column_name(statement,i)]];
                }
            }
            [thisArray addObject:[NSDictionary dictionaryWithDictionary:thisDict]];
        }
    }
    sqlite3_finalize(statement);
    return thisArray;
}

- (NSDictionary *)lookupRowForSQL:(NSString *)sql {
    sqlite3_stmt *statement;
    id result;
    NSMutableDictionary *thisDict = [NSMutableDictionary dictionaryWithCapacity:4];
    if (statement = [self prepare:sql]) {
        if (sqlite3_step(statement) == SQLITE_ROW) {
            for (int i = 0 ; i < sqlite3_column_count(statement) ; i++) {
                if (strcasecmp(sqlite3_column_decltype(statement,i),"Boolean") == 0) {
                    result = [NSNumber numberWithBool:(BOOL)sqlite3_column_int(statement,i)];
                } else if (sqlite3_column_type(statement, i) == SQLITE_TEXT) {
                    result = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,i)];
                } else if (sqlite3_column_type(statement,i) == SQLITE_INTEGER) {
                    result = [NSNumber numberWithInt:(int)sqlite3_column_int(statement,i)];
                } else if (sqlite3_column_type(statement,i) == SQLITE_FLOAT) {
                    result = [NSNumber numberWithFloat:(float)sqlite3_column_double(statement,i)];
                } else {
                    if((char *)sqlite3_column_text(statement,i) != NULL){
                        result = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,i)];
                    }
                }
                if (result) {
                    [thisDict setObject:result
                                 forKey:[NSString stringWithUTF8String:sqlite3_column_name(statement,i)]];
                }
            }
        }
    }
    sqlite3_finalize(statement);
    return thisDict;
}

- (id)lookupColForSQL:(NSString *)sql {
    
    sqlite3_stmt *statement;
    id result;
    if (statement = [self prepare:sql]) {
        if (sqlite3_step(statement) == SQLITE_ROW) {
            if (strcasecmp(sqlite3_column_decltype(statement,0),"Boolean") == 0) {
                result = [NSNumber numberWithBool:(BOOL)sqlite3_column_int(statement,0)];
            } else if (sqlite3_column_type(statement, 0) == SQLITE_TEXT) {
                result = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,0)];
            } else if (sqlite3_column_type(statement,0) == SQLITE_INTEGER) {
                result = [NSNumber numberWithInt:(int)sqlite3_column_int(statement,0)];
            } else if (sqlite3_column_type(statement,0) == SQLITE_FLOAT) {
                result = [NSNumber numberWithDouble:(double)sqlite3_column_double(statement,0)];
            } else {
                result = [NSString stringWithUTF8String:(char *)sqlite3_column_text(statement,0)];
            }
        }
    }
    sqlite3_finalize(statement);
    return result;
    
}

// Simple use of COUNTS, MAX, etc.

- (int)lookupCountWhere:(NSString *)where forTable:(NSString *)table {
    
    int tableCount = 0;
    NSString *sql = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE %@",
                     table,where];
    sqlite3_stmt *statement;
    
    if (statement = [self prepare:sql]) {
        if (sqlite3_step(statement) == SQLITE_ROW) {
            tableCount = sqlite3_column_int(statement,0);
        }
    }
    sqlite3_finalize(statement);
    return tableCount;
    
}

- (int)lookupMax:(NSString *)key Where:(NSString *)where forTable:(NSString *)table {
    
    int tableMax = 0;
    NSString *sql = [NSString stringWithFormat:@"SELECT MAX(%@) FROM %@ WHERE %@",
                     key,table,where];
    sqlite3_stmt *statement;
    if (statement = [self prepare:sql]) {
        if (sqlite3_step(statement) == SQLITE_ROW) {
            tableMax = sqlite3_column_int(statement,0);
        }
    }
    sqlite3_finalize(statement);
    return tableMax;
    
}

- (int)lookupSum:(NSString *)key Where:(NSString *)where forTable:(NSString *)table {
    
    int tableSum = 0;
    NSString *sql = [NSString stringWithFormat:@"SELECT SUM(%@) FROM %@ WHERE %@",
                     key,table,where];
    sqlite3_stmt *statement;
    if (statement = [self prepare:sql]) {
        if (sqlite3_step(statement) == SQLITE_ROW) {
            tableSum = sqlite3_column_int(statement,0);
        }
    }
    sqlite3_finalize(statement);
    return tableSum;
    
}

//createDatabase
-(void)CreateDB:(NSDictionary *)dbData forTable:(NSString *)table {
    
    NSMutableString *Checksql = [NSMutableString stringWithCapacity:16];
    [Checksql appendFormat:@"PRAGMA table_info(%@) ",table];
    NSArray *ColomsKeys = [self lookupAllForSQL:Checksql];
    if([ColomsKeys count] >= 1){
        [self CheckNewField:dbData forTable:table];
        return;
    }
    
    NSMutableString *sql = [NSMutableString stringWithCapacity:16];
    [sql appendFormat:@"CREATE  TABLE  IF NOT EXISTS %@ (",table];
    NSMutableString *PrimaryKey = [NSMutableString stringWithCapacity:16];
    NSArray *dataKeys = [dbData allKeys];
    for (int i = 0 ; i < [dataKeys count] ; i++) {
        [sql appendFormat:@"%@ TEXT",[dataKeys objectAtIndex:i]];
        if (i + 1 < [dbData count]) {
            [sql appendFormat:@", "];
        }
        if([[dataKeys objectAtIndex:i] rangeOfString:@"id"].location != NSNotFound){
            //found primary key
            [PrimaryKey appendFormat:@"%@",[dataKeys objectAtIndex:i]];
            [PrimaryKey appendFormat:@","];
        }
    }
    if ([PrimaryKey length] > 0) {
        [PrimaryKey deleteCharactersInRange:NSMakeRange([PrimaryKey length]-1, 1)];
    } else {
        //no characters to delete... attempting to do so will result in a crash
    }
    [sql appendFormat:@", PRIMARY KEY(%@))",PrimaryKey];
    [self lookupRowForSQL:sql];
    NSLog(@"%@", [self lookupRowForSQL:sql]);
    
    
}

-(BOOL)CheckNewField:(NSDictionary *)dbData forTable:(NSString *)table {
    
    NSMutableString *sql = [NSMutableString stringWithCapacity:16];
    [sql appendFormat:@"PRAGMA table_info(%@) ",table];
    NSArray *dataKeys = [dbData allKeys];
    NSMutableArray *ColomnKeys = [[NSMutableArray alloc] init]; //[self lookupAllForSQL:sql];
    
    for (NSDictionary *dict in [self lookupAllForSQL:sql]) {
        [ColomnKeys addObject:[dict valueForKey:@"name"]];
    }
    
    BOOL flag= false;
    
    for (NSString *key in dataKeys) {
        if(![ColomnKeys containsObject:key]){
            flag = true;
            //new key added
            [self lookupRowForSQL:[NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ TEXT",table,key]];
            
        }
    }
    return  true;
}

// INSERTing and UPDATing

- (void)insertArray:(NSArray *)dbData forTable:(NSString *)table {
    
    //    [self CreateDB:[dbData objectAtIndex:0] forTable:table];
    //
    //    NSMutableString *sql = [NSMutableString stringWithCapacity:16];
    //    [sql appendFormat:@"INSERT INTO %@ (",table];
    //
    //    for (int i = 0 ; i < [dbData count] ; i++) {
    //        [sql appendFormat:@"%@",[[dbData objectAtIndex:i] objectForKey:@"key"]];
    //        if (i + 1 < [dbData count]) {
    //            [sql appendFormat:@", "];
    //        }
    //    }
    //    [sql appendFormat:@") VALUES("];
    //    for (int i = 0 ; i < [dbData count] ; i++) {
    //        if ([[[dbData objectAtIndex:i] objectForKey:@"value"] intValue]) {
    //            [sql appendFormat:@"%d",[[[dbData objectAtIndex:i] objectForKey:@"value"] intValue]];
    //        } else {
    //            [sql appendFormat:@"'%@'",[[dbData objectAtIndex:i] objectForKey:@"value"]];
    //        }
    //        if (i + 1 < [dbData count]) {
    //            [sql appendFormat:@", "];
    //        }
    //    }
    //    [sql appendFormat:@")"];
    //    [self runDynamicSQL:sql forTable:table];
    
    
    for (NSDictionary *dict in dbData) {
        [self insertDictionary:dict forTable:table];
    }
}

- (void)insertDictionary:(NSDictionary *)dbData forTable:(NSString *)table {
    
    [self CreateDB:dbData  forTable:table];
    
    NSMutableString *sql = [NSMutableString stringWithCapacity:36];
    [sql appendFormat:@"INSERT INTO %@ (",table];
    
    NSArray *dataKeys = [dbData allKeys];
    for (int i = 0 ; i < [dataKeys count] ; i++) {
        [sql appendFormat:@"%@",[dataKeys objectAtIndex:i]];
        if (i + 1 < [dbData count]) {
            [sql appendFormat:@", "];
        }
    }
    
    [sql appendFormat:@") VALUES("];
    for (int i = 0 ; i < [dataKeys count] ; i++) {
        [sql appendFormat:@"'%@'",[dbData objectForKey:[dataKeys objectAtIndex:i]]];
        if (i + 1 < [dbData count]) {
            [sql appendFormat:@", "];
        }
        
    }
    
    [sql appendFormat:@")"];
    NSLog(@"%@",sql);
    [self runDynamicSQL:sql forTable:table];
}

- (void)updateArray:(NSArray *)dbData forTable:(NSString *)table {
    
    [self updateArray:dbData forTable:table where:NULL];
}

- (void)updateArray:(NSArray *)dbData forTable:(NSString *)table where:(NSString *)where {
    [self CreateDB:[dbData objectAtIndex:0]  forTable:table];
    NSMutableString *sql = [NSMutableString stringWithCapacity:16];
    [sql appendFormat:@"UPDATE %@ SET ",table];
    
    for (int i = 0 ; i < [dbData count] ; i++) {
        if ([[[dbData objectAtIndex:i] objectForKey:@"value"] intValue]) {
            [sql appendFormat:@"%@=%@",
             [[dbData objectAtIndex:i] objectForKey:@"key"],
             [[dbData objectAtIndex:i] objectForKey:@"value"]];
        } else {
            [sql appendFormat:@"%@='%@'",
             [[dbData objectAtIndex:i] objectForKey:@"key"],
             [[dbData objectAtIndex:i] objectForKey:@"value"]];
        }
        if (i + 1 < [dbData count]) {
            [sql appendFormat:@", "];
        }
    }
    if (where != NULL) {
        [sql appendFormat:@" WHERE %@",where];
    } else {
        [sql appendFormat:@" WHERE 1",where];
    }
    
    [self runDynamicSQL:sql forTable:table];
    
}

- (void)updateDictionary:(NSDictionary *)dbData forTable:(NSString *)table {
    [self updateDictionary:dbData forTable:table where:NULL];
}

- (void)updateDictionary:(NSDictionary *)dbData forTable:(NSString *)table where:(NSString *)where {
    
    NSMutableString *sql = [NSMutableString stringWithCapacity:16];
    [sql appendFormat:@"UPDATE %@ SET ",table];
    
    NSArray *dataKeys = [dbData allKeys];
    for (int i = 0 ; i < [dataKeys count] ; i++) {
        //        if ([[dbData objectForKey:[dataKeys objectAtIndex:i]] intValue]) {
        //            [sql appendFormat:@"%@=%@",
        //             [dataKeys objectAtIndex:i],
        //             [dbData objectForKey:[dataKeys objectAtIndex:i]]];
        //        } else {
        //            [sql appendFormat:@"%@='%@'",
        //             [dataKeys objectAtIndex:i],
        //             [dbData objectForKey:[dataKeys objectAtIndex:i]]];
        //        }
        [sql appendFormat:@"%@='%@'",
         [dataKeys objectAtIndex:i],
         [dbData objectForKey:[dataKeys objectAtIndex:i]]];
        
        if (i + 1 < [dbData count]) {
            [sql appendFormat:@", "];
        }
    }
    if (where != NULL) {
        [sql appendFormat:@" WHERE %@",where];
    }
    NSLog(@"%@",sql);
    [self runDynamicSQL:sql forTable:table];
}

- (void)updateSQL:(NSString *)sql forTable:(NSString *)table {
    
    NSMutableString *sql1 = [NSMutableString stringWithCapacity:16];
    [sql1 appendFormat:@"UPDATE %@ SET %@",table,sql];

    [self runDynamicSQL:sql1 forTable:table];
}

- (void)deleteWhere:(NSString *)where forTable:(NSString *)table {
    
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE %@",
                     table,where];
    [self runDynamicSQL:sql forTable:table];
}

- (void) deleteAllFrom:(NSString *)table{
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@", table];
    [self runDynamicSQL:sql forTable:table];
}

// INSERT/UPDATE/DELETE Subroutines

- (BOOL)runDynamicSQL:(NSString *)sql forTable:(NSString *)table {
    
    
    int result;
    NSAssert1(self.dynamic == 1,@"Tried to use a dynamic function on a static database",NULL);
    sqlite3_stmt *statement;
    if ((statement = [self prepare:sql])) {
        result = sqlite3_step(statement);
    }
    sqlite3_finalize(statement);
    if (result) {
        if (self.delegate != NULL && [self.delegate respondsToSelector:@selector(databaseTableWasUpdated:)]) {
            [delegate databaseTableWasUpdated:table];
        }
        return YES;
    } else {
        return NO;
    }
    
}

- (NSString *)escapeString:(NSString *)dirtyString{
    NSString *cleanString = [dirtyString stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
    //[cleanString autorelease];
    
    return cleanString;
}


-(NSString *) getDbFilePath
{
    NSString * docsPath= NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES)[0];
    return [docsPath stringByAppendingPathComponent:@"studets.db"];

}




// requirements for closing things down

- (void)dealloc {
    [self close];
    //[delegate release];
    // [super dealloc];
}

- (void)close {
    
    if (dbh) {
        sqlite3_close(dbh);
    }
}

@end