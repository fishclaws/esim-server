import { useState, useEffect } from "react";
import UploadService from "../services/FileUploadService";
import IFile from "../types/File";
import { ImageTools } from "../ImageTools";

const ImageUpload: React.FC = () => {
  const [currentImage, setCurrentImage] = useState<File>();
  const [previewImage, setPreviewImage] = useState<string>("");
  const [progress, setProgress] = useState<number>(0);
  const [message, setMessage] = useState<string>("");
  const [imageInfos, setImageInfos] = useState<Array<IFile>>([]);

  useEffect(() => {
    // UploadService.getFiles().then((response) => {
    //   setImageInfos(response.data);
    // });
  }, []);

  const selectImage = (event: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFiles = event.target.files as FileList;
    setCurrentImage(selectedFiles?.[0]);
    setPreviewImage(URL.createObjectURL(selectedFiles?.[0]));
    setProgress(0);
  };

  const resizeImage = (imgToResize: any, resizingFactor = 0.2) => {
    const canvas = document.createElement("canvas");
    const context = canvas.getContext("2d");
  
    const originalWidth = imgToResize.width;
    const originalHeight = imgToResize.height;
  
    const canvasWidth = originalWidth * resizingFactor;
    const canvasHeight = originalHeight * resizingFactor;
  
    canvas.width = canvasWidth;
    canvas.height = canvasHeight;
  
    context!.drawImage(
      imgToResize,
      0,
      0,
      originalWidth * resizingFactor,
      originalHeight * resizingFactor
    );
    return canvas.toDataURL();
  }

  const upload = () => {
    setProgress(0);
    if (!currentImage) return;
    ImageTools.resize(currentImage, {width:540, height:1200}, (file: File) => {
      UploadService.upload(file, (event: any) => {
        setProgress(Math.round((100 * event.loaded) / event.total));
      })
        .then((response) => {
          setMessage(response.data.message);
          return UploadService.getFiles();
        })
        .then((files) => {
          setImageInfos(files.data);
        })
        .catch((err) => {
          setProgress(0);
          console.log(err)
          if (err.response && err.response.data && err.response.data.message) {
            setMessage(err.response.data.message);
          } else {
            setMessage("Could not upload the Image!");
          }
  
          setCurrentImage(undefined);
        });
    })
    
  };

  return (
    <div>
      <div className="row">
        <div className="col-8">
          <label className="button-23">
            <input type="file" accept="image/*" onChange={selectImage} />
          </label>
        </div>
        <br></br>
        <div className="col-4">
          <button
            className="button-23"
            disabled={!currentImage}
            onClick={upload}
          >
            Upload
          </button>
        </div>
      </div>

      {currentImage && progress > 0 && (
        <div className="progress my-3">
          <div
            className="progress-bar progress-bar-info"
            role="progressbar"
            aria-valuenow={progress}
            aria-valuemin={0}
            aria-valuemax={100}
            style={{ width: progress + "%" }}
          >
            {progress}%
          </div>
        </div>
      )}

      {previewImage && (
        <div>
          <img className="preview" src={previewImage} alt="" />
        </div>
      )}

      {message && (
        <div className="alert alert-secondary mt-3" role="alert">
          {message}
        </div>
      )}
    </div>
  );
};

export default ImageUpload;