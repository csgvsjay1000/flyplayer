//
//  FlyPlayerHeader.h
//  flyplayer
//
//  Created by feng on 16/7/19.
//  Copyright © 2016年 feng. All rights reserved.
//

#ifndef FlyPlayerHeader_h
#define FlyPlayerHeader_h
#import "avformat.h"
#import "avcodec.h"
#import "log.h"
#import "swscale.h"
#import <pthread.h>
#import "swresample.h"
#import "time.h"
#import <AVFoundation/AVFoundation.h>
#import <sys/time.h>

static AVPacket flush_pkt;

typedef struct MyAVPacketList {
    AVPacket pkt;
    struct MyAVPacketList *next;
    int serial;
} MyAVPacketList;

typedef struct PacketQueue {
    MyAVPacketList *first_pkt, *last_pkt;
    int nb_packets;
    int size;
    int abort_request;
    int serial;
    pthread_mutex_t mutex;
    pthread_cond_t cond;
} PacketQueue;

static void packet_queue_init(PacketQueue *q){
    memset(q, 0, sizeof(PacketQueue));
    pthread_mutex_init(&q->mutex, NULL);
    pthread_cond_init(&q->cond, NULL);
    q->abort_request = 1;
}

static int packet_queue_put_private(PacketQueue *q, AVPacket *pkt){
    MyAVPacketList *pkt1;
    if (q->abort_request)
        return -1;
    pkt1 = av_malloc(sizeof(MyAVPacketList));
    if (!pkt1)
        return -1;
    pkt1->pkt = *pkt;
    pkt1->next = NULL;
    if (pkt == &flush_pkt)
        q->serial++;
    pkt1->serial = q->serial;
    if (!q->last_pkt)
        q->first_pkt = pkt1;
    else
        q->last_pkt->next = pkt1;
    q->last_pkt = pkt1;
    q->nb_packets++;
    q->size += pkt1->pkt.size + sizeof(*pkt1);
    pthread_cond_wait(&q->cond, &q->mutex);
    return 0;
}


static void packet_queue_start(PacketQueue *q){
    pthread_mutex_lock(&q->mutex);
    q->abort_request = 0;
    packet_queue_put_private(q, &flush_pkt);
    pthread_mutex_unlock(&q->mutex);
}

typedef struct Clock {
    double pts;           /* clock base */
    double pts_drift;
    double last_updated;
    double speed;
    int serial;           /* clock is based on a packet with this serial */
    int paused;
    int *queue_serial;
}Clock;

typedef struct VideoPicture {
    double pts;             // presentation timestamp for this picture
    double duration;        // estimated duration based on frame rate
    int64_t pos;            // byte position in file
    AVFrame* rawdata;
    int width, height; /* source height & width */
    int allocated;
    int reallocate;
    int serial;
    
    AVRational sar;
}VideoPicture;

typedef struct VideoState {
    int abort_request;
    char filename[1024];
    AVInputFormat *iformat;
    AVFormatContext *ic;
    Clock audclk;
    Clock vidclk;
    
    int64_t start_time;

    int av_sync_type;
    
    pthread_mutex_t pictq_mutex;
    pthread_cond_t pictq_cond;
    
    int audio_stream;

    
    //音频
    PacketQueue audioq;
    int audio_clock_serial;
    int audio_last_serial;
    AVStream *audio_st;
    
    int video_stream;

    //视频
    PacketQueue videoq;
    double max_frame_duration; 
    AVStream *video_st;
    
    int last_video_stream, last_audio_stream, last_subtitle_stream;

    
    pthread_cond_t continue_read_thread;
    
}VideoState;



static void set_clock_at(Clock *c, double pts, int serial, double time){
    c->pts = pts;
    c->last_updated = time;
    c->pts_drift = c->pts - time;
    c->serial = serial;
}

static void set_clock(Clock *c, double pts, int serial){
    double time = av_gettime() / 1000000.0;
    set_clock_at(c, pts, serial, time);
}

static void init_clock(Clock *c, int *queue_serial){
    c->speed = 1.0;
    c->paused = 0;
    c->queue_serial = queue_serial;
    set_clock(c, NAN, -1);
}



#endif /* FlyPlayerHeader_h */
