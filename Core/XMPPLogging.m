#import <Foundation/Foundation.h>
#import <objc/message.h>

NSString *XMPPExtractFileNameWithoutExtension(const char *filePath, BOOL copy)
{
    if (filePath == NULL)
    {
        return nil;
    }

    char *lastSlash = NULL;
    char *lastDot = NULL;

    char *p = (char *)filePath;

    while (*p != '\0')
    {
        if (*p == '/')
        {
            lastSlash = p;
        }
        else if (*p == '.')
        {
            lastDot = p;
        }
        p++;
    }

    char *subStr;
    NSUInteger subLen;

    if (lastSlash)
    {
        if (lastDot)
        {
            // lastSlash -> lastDot
            subStr = lastSlash + 1;
            subLen = (NSUInteger)(lastDot - subStr);
        }
        else
        {
            // lastSlash -> endOfString
            subStr = lastSlash + 1;
            subLen = (NSUInteger)(p - subStr);
        }
    }
    else
    {
        if (lastDot)
        {
            // startOfString -> lastDot
            subStr = (char *)filePath;
            subLen = (NSUInteger)(lastDot - subStr);
        }
        else
        {
            // startOfString -> endOfString
            subStr = (char *)filePath;
            subLen = (NSUInteger)(p - subStr);
        }
    }

    if (copy)
    {
        return [[NSString alloc] initWithBytes:subStr
                                        length:subLen
                                      encoding:NSUTF8StringEncoding];
    }
    else
    {
        // We can take advantage of the fact that __FILE__ is a string literal.
        // Specifically, we don't need to waste time copying the string.
        // We can just tell NSString to point to a range within the string literal.
        return [[NSString alloc] initWithBytesNoCopy:subStr
                                              length:subLen
                                            encoding:NSUTF8StringEncoding
                                        freeWhenDone:NO];
    }
}

@implementation XMPPLog

+ (void)flushLog
{
    static Class DDLogClass;
    static SEL selector;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        DDLogClass = NSClassFromString(@"DDLog");
        selector = @selector(flushLog);
        if (![DDLogClass respondsToSelector:selector])
        {
            NSLog(@"Unsupported CocoaLumberjack version");
            DDLogClass = nil;
        }
    });

    ((void (*)(id, SEL))objc_msgSend)(DDLogClass, selector);
}

+ (void)log:(BOOL)asynchronous
      level:(NSUInteger)level
       flag:(NSUInteger)flag
    context:(NSInteger)context
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
        tag:(id)tag
     format:(NSString *)format, ...
{
    static Class DDLogClass;
    static SEL selector;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        DDLogClass = NSClassFromString(@"DDLog");
        selector = NSSelectorFromString(@"log:level:flag:context:file:function:line:tag:format:args:");
        if (![DDLogClass respondsToSelector:selector])
        {
            NSLog(@"Unsupported CocoaLumberjack version");
            DDLogClass = nil;
        }
    });

    if (format)
    {
        va_list args;
        va_start(args, format);
        if (DDLogClass)
        {
            ((void (*)(id, SEL, BOOL, NSUInteger, NSUInteger, NSInteger, const char *, const char *, NSUInteger, id, NSString *, ...))objc_msgSend)(DDLogClass, selector, asynchronous, level, flag, context, file, function, line, tag, format, args);
        }
        else
        {
            NSLog(@"[%s:%zd] [%s] %@", file, line, function, [[NSString alloc] initWithFormat:format arguments:args]);
        }
        va_end(args);
    }
}

@end
