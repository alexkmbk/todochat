package utils

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"errors"
	"image"
	"io"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	_ "image/gif"
	"image/jpeg"
	"image/png"
	_ "image/png"

	_ "golang.org/x/image/bmp"

	_ "golang.org/x/image/webp"

	//"github.com/google/uuid"
	//"github.com/h2non/bimg"

	"github.com/nfnt/resize"
	_ "golang.org/x/image/bmp"

	//"github.com/kolesa-team/go-webp/webp"
	//"github.com/tidbyt/go-libwebp/webp"
	log "github.com/labstack/gommon/log"
)

var DoLogs = false

func FromBase64(base64Text string) ([]byte, error) {
	return base64.StdEncoding.DecodeString(base64Text)
}

func ToBase64(data []byte) string {
	return base64.StdEncoding.EncodeToString(data)
}

func FileExists(path string) bool {
	if _, err := os.Stat(path); errors.Is(err, os.ErrNotExist) {
		return false
	}
	return true
}

func GetCurrentDir() string {

	exePath, err := os.Executable()
	if err == nil {
		return filepath.Dir(exePath)
	}

	res, err := os.Getwd()
	if err != nil {
		return ""
	}
	return res
	//filepath.Join()
}

func ResizeImageByHeight(data []byte, height uint) ([]byte, error, int, int) {
	var newImage []byte

	reader := bytes.NewReader(data)
	imageData, _, err := image.Decode(reader)
	if err != nil {
		return newImage, err, 0, 0
	}

	m := resize.Resize(0, height, imageData, resize.Lanczos3)

	buf := new(bytes.Buffer)
	err = jpeg.Encode(buf, m, nil)
	newImage = buf.Bytes()

	g := m.Bounds()

	// Get height and width
	resultHeight := g.Dy()
	resultWidth := g.Dx()

	/*newImage, err := bimg.NewImage(buffer).CropByHeight(200)
	if err != nil {
		return newImage, err
	}

	/*size, _ := bimg.Size(newImage)
	if size.Height != height {
		return newImage, error()
	}*/
	return newImage, nil, resultHeight, resultWidth
}

// Guess image format from gif/jpeg/png/webp
func GuessImageFormat(data []byte) (format string, err error) {
	reader := bytes.NewReader(data)
	_, format, err = image.DecodeConfig(reader)
	return
}

func OptimizeImageSize(data []byte, ext string) ([]byte, string) {

	var newImage []byte

	reader := bytes.NewReader(data)

	_, format, err := image.DecodeConfig(reader)

	if err != nil {
		return data, ext
	}

	if strings.ToLower(format) != "bmp" {
		return data, ext
	}
	reader.Seek(0, 0)
	imageData, _, err := image.Decode(reader)
	if err != nil {
		return data, ext
	}
	buf := new(bytes.Buffer)
	err = png.Encode(buf, imageData)
	if err != nil {
		return data, ext
	}
	newImage = buf.Bytes()
	//err = os.WriteFile(filepath.Join(FileStoragePath, filename), newImage, 0644)

	return newImage, ".png"
}

/*
	func ResizeImageByHeight__(data []byte, height int) ([]byte, error) {
		var newImage []byte

		reader := bytes.NewReader(data)

		imageInfo, _, err := image.DecodeConfig(reader)
		if err != nil {
			return newImage, err
		}

		image, _, err := image.Decode(reader)
		if err != nil {
			return newImage, err
		}

		scale := height / imageInfo.Height
		inverted := effect.Invert(image)

		resized := transform.Resize(inverted, height, imageInfo.Width*scale, transform.Linear)

		buf := new(bytes.Buffer)
		err = jpeg.Encode(buf, resized, nil)
		newImage = buf.Bytes()

		return newImage, nil
	}
*/
func ToInt64(str string) int64 {
	res, err := strconv.ParseInt(str, 10, 64)
	if err != nil {
		res = 0
	}
	return res
}

func StrMap() map[string]string {
	return make(map[string]string)
}

func Map() map[string]interface{} {
	return make(map[string]interface{})
}

func FromJson(r io.Reader) (interface{}, error) {
	var res interface{}
	decoder := json.NewDecoder(r)
	error := decoder.Decode(res)
	return res, error
}

func Log(str interface{}) {
	if DoLogs {
		log.Info(str)
	}
}

func Log_fatal(err interface{}) {
	if DoLogs {
		log.Fatal(err)
	}
}

func Log_warn(err interface{}) {
	if DoLogs {
		log.Warn(err)
	}
}

/*func Write(){
	pw := bufio.NewWriterSize(w, 100000) // Bigger writer of 10kb
	fmt.Println("Buffer size", pw.Size())

	res, _ := json.Marshal(messages)
	pw.Write(res)
	//_, err := io.WriteString(pw, )

	if err != nil {
		fmt.Println(err)
	}

	if pw.Buffered() > 0 {
		fmt.Println("Bufferred", pw.Buffered())
		pw.Flush() // Important step read my note following this code snippet
	}

}*/

// The mime type of the image is changed, it is compressed and then saved in the specified folder.
/*func ConvertImagetoWebP(data []byte, quality int, dirname string) (string, error) {
/*filename := strings.Replace(uuid.New().String(), "-", "", -1) + ".webp"

converted, err := bimg.NewImage(buffer).Convert(bimg.WEBP)
if err != nil {
	return filename, err
}

processed, err := bimg.NewImage(converted).Process(bimg.Options{Quality: quality})
if err != nil {
	return filename, err
}

writeError := bimg.Write(fmt.Sprintf("./"+dirname+"/%s", filename), processed)
if writeError != nil {
	return filename, writeError
}

return filename, nil*/

/*filename := strings.Replace(uuid.New().String(), "-", "", -1) + ".webp"

	var newImage []byte

	reader := bytes.NewReader(data)
	imageData, _, err := image.Decode(reader)
	if err != nil {
		return "", err
	}

	buf := new(bytes.Buffer)
	err = webp.EncodeRGBA(buf, imageData, nil)
	newImage = buf.Bytes()

	err = os.WriteFile(filepath.Join(FileStoragePath, filename), newImage, 0644)
	if err != nil {
		return "", err
	}

	return filename, nil
}*/
