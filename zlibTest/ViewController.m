//
//  ViewController.m
//  zlibTest
//
//  Created by rbq on 2024/5/20.
//

#import "ViewController.h"
#import "zlib.h"
#include <stdio.h>
#include <string.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 使用示例
    NSString *originalString = @"这是一个需要压缩的中文字符串";
    NSData *originalData = [originalString dataUsingEncoding:NSUTF8StringEncoding];
    NSData *compressedData = [self compressData:originalData];
    NSData *decompressedData = [self decompressData:compressedData];
    NSString *decompressedString = [[NSString alloc] initWithData:decompressedData encoding:NSUTF8StringEncoding];
    
    NSString *originalHexString = [self hexStringFromData:originalData];
    NSString *compressedHexString = [self hexStringFromData:compressedData];
    NSString *decompressedHexString = [self hexStringFromData:decompressedData];


    NSLog(@"原始字符串originalString: %@\n", originalString);
    NSLog(@"原始hex字符串originalHexString: %@\n", originalHexString);
    NSLog(@"压缩后hex字符串compressedHexString: %@\n", compressedHexString);
    NSLog(@"解压后hex字符串decompressedHexString: %@\n", decompressedHexString);
    NSLog(@"解压缩后字符串decompressedString: %@\n", decompressedString);
    
    NSData *compressedData3 = [self compressData:originalData withLevel:Z_RLE];
    NSData *decompressedData3 = [self decompressData:compressedData3];
    NSData *compressedData9 = [self compressData:originalData withLevel:Z_BEST_COMPRESSION];
    NSData *decompressedData9 = [self decompressData:compressedData9];
    
    NSString *decompressedHexString3 = [self hexStringFromData:decompressedData3];
    NSString *decompressedHexString9 = [self hexStringFromData:decompressedData9];
    
    NSLog(@"解压后hex字符串decompressedHexString3: %@\n", decompressedHexString3);
    NSLog(@"解压后hex字符串decompressedHexString9: %@\n", decompressedHexString9);
    
}

// NSData 转换为 16 进制字符串，并在每个 16 进制数之间添加空格
- (NSString *)hexStringFromData:(NSData *)data {
    const unsigned char *dataBuffer = (const unsigned char *)[data bytes];

    if (!dataBuffer) {
        return [NSString string];
    }

    NSUInteger dataLength  = [data length];
    NSMutableString *hexString  = [NSMutableString stringWithCapacity:(dataLength * 3)]; // 每个字节现在占用3个字符位置（2个字符和1个空格）

    for (int i = 0; i < dataLength; ++i) {
        [hexString appendFormat:@"%02x ", dataBuffer[i]]; // 在 "%02x" 后面添加一个空格
    }

    return [NSString stringWithString:hexString];
}


// 压缩函数
-(NSData *)compressData:(NSData *)uncompressedData {
    if (!uncompressedData || [uncompressedData length] == 0) return nil;

    z_stream strm;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.avail_in = (uInt)[uncompressedData length];
    strm.next_in = (Bytef *)[uncompressedData bytes];
    strm.total_out = 0;

    if (deflateInit(&strm, Z_DEFAULT_COMPRESSION) != Z_OK) return nil;

    // 计算压缩后的长度
    NSMutableData *compressedData = [NSMutableData dataWithLength:compressBound(strm.avail_in)];
    do {
        strm.avail_out = (uInt)[compressedData length] - (uInt)strm.total_out;
        strm.next_out = [compressedData mutableBytes] + strm.total_out;
        deflate(&strm, Z_FINISH);
    } while (strm.avail_out == 0);

    deflateEnd(&strm);

    [compressedData setLength:strm.total_out];
    return [NSData dataWithData:compressedData];
}

// 压缩函数，增加压缩等级设置
-(NSData *)compressData:(NSData *)uncompressedData withLevel:(int)level {
    if (!uncompressedData || [uncompressedData length] == 0) return nil;

    z_stream strm;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.avail_in = (uInt)[uncompressedData length];
    strm.next_in = (Bytef *)[uncompressedData bytes];
    strm.total_out = 0;

    // 设置压缩等级
    if (deflateInit(&strm, level) != Z_OK) return nil;

    // 计算压缩后的长度
    NSMutableData *compressedData = [NSMutableData dataWithLength:compressBound(strm.avail_in)];
    do {
        strm.avail_out = (uInt)[compressedData length] - (uInt)strm.total_out;
        strm.next_out = [compressedData mutableBytes] + strm.total_out;
        int deflateStatus = deflate(&strm, Z_FINISH);
        if (deflateStatus == Z_STREAM_ERROR) {
            deflateEnd(&strm);
            return nil;
        }
    } while (strm.avail_out == 0);

    deflateEnd(&strm);

    [compressedData setLength:strm.total_out];
    return [NSData dataWithData:compressedData];
}


// 解压缩函数
-(NSData *)decompressData:(NSData *)compressedData {
    if (!compressedData || [compressedData length] == 0) return nil;

    z_stream strm;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.avail_in = (uInt)[compressedData length];
    strm.next_in = (Bytef *)[compressedData bytes];

    if (inflateInit(&strm) != Z_OK) return nil;

    // 估计解压缩后的长度
    NSMutableData *decompressedData = [NSMutableData dataWithLength:(strm.avail_in * 4)];
    int status;
    do {
        strm.avail_out = (uInt)[decompressedData length] - (uInt)strm.total_out;
        strm.next_out = [decompressedData mutableBytes] + strm.total_out;
        status = inflate(&strm, Z_NO_FLUSH);
        if (status == Z_STREAM_ERROR || status == Z_NEED_DICT || status == Z_DATA_ERROR || status == Z_MEM_ERROR) {
            inflateEnd(&strm);
            return nil;
        }
    } while (status != Z_STREAM_END);

    inflateEnd(&strm);

    [decompressedData setLength:strm.total_out];
    return [NSData dataWithData:decompressedData];
}


@end
