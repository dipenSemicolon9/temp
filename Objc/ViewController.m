
#import "ViewController.h"

@interface ViewController ()

@property (strong, nonatomic) NSURLConnection *connectionManager;
@property (strong, nonatomic) NSMutableData *downloadedMutableData;
@property (strong, nonatomic) NSURLResponse *urlResponse;

@end

@implementation ViewController{
    
#define IMAGE_URL @"http://img1.wikia.nocookie.net/__cb20111229061816/lego/images/b/b8/Ws-space-apple-logo.jpg"
}

- (void)viewDidLoad
{
    [super viewDidLoad];   
}

-(IBAction)downloadImage :(id)sender{
    
    self.btn_download.enabled = NO;
    self.downloadedMutableData = [[NSMutableData alloc] init];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:IMAGE_URL]
                                                cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                            timeoutInterval:60.0];
    self.connectionManager = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Delegate Methods
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"%lld", response.expectedContentLength);
    self.urlResponse = response;
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.downloadedMutableData appendData:data];
    self.progressView.progress = ((100.0/self.urlResponse.expectedContentLength)*self.downloadedMutableData.length)/100;
    
    float per = ((100.0/self.urlResponse.expectedContentLength)*self.downloadedMutableData.length);
    self.lbl_download.text = [NSString stringWithFormat:@"%0.f%%", per];
    
    if (self.progressView.progress == 1) {
        self.progressView.hidden = YES;
        self.btn_download.enabled = YES;
    } else {
        self.progressView.hidden = NO;
    }
    
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    self.imageView.image = [UIImage imageWithData:self.downloadedMutableData];
    self.lbl_download.text = @"Download Complete";
}

@end