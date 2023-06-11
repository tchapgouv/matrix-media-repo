package pool

import (
	"github.com/getsentry/sentry-go"
	"github.com/sirupsen/logrus"
	"github.com/turt2live/matrix-media-repo/common/config"
)

var DownloadQueue *Queue
var ThumbnailQueue *Queue

func Init() {
	var err error
	if DownloadQueue, err = NewQueue(config.Get().Downloads.NumWorkers, "downloads"); err != nil {
		sentry.CaptureException(err)
		logrus.Error("Error setting up downloads queue")
		logrus.Fatal(err)
	}
	if ThumbnailQueue, err = NewQueue(config.Get().Thumbnails.NumWorkers, "thumbnails"); err != nil {
		sentry.CaptureException(err)
		logrus.Error("Error setting up thumbnails queue")
		logrus.Fatal(err)
	}
}

func AdjustSize() {
	DownloadQueue.pool.Tune(config.Get().Downloads.NumWorkers)
	ThumbnailQueue.pool.Tune(config.Get().Thumbnails.NumWorkers)
}

func Drain() {
	DownloadQueue.pool.Release()
	ThumbnailQueue.pool.Release()
}