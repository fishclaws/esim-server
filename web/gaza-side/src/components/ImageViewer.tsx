import { useState, useEffect } from "react";
import UploadService from "../services/FileUploadService";
import IFile from "../types/File";
import './ImageViewer.css';

const ImageViewer: React.FC = () => {
  const [currentImage, setCurrentImage] = useState<File>();
  const [previewImage, setPreviewImage] = useState<string>("");
  const [progress, setProgress] = useState<number>(0);
  const [message, setMessage] = useState<string>("");
  const [imageInfos, setImageInfos] = useState<Array<IFile>>([]);
  const [selectedImage, setSelectedImage] = useState<number>(-1);

  useEffect(() => {
    UploadService.getFiles().then((response) => {
      console.log(response)
      setImageInfos(response.data);
    });
  }, []);

  const selectImage = (event: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFiles = event.target.files as FileList;
    setCurrentImage(selectedFiles?.[0]);
    setPreviewImage(URL.createObjectURL(selectedFiles?.[0]));
    setProgress(0);
  };

  const deleteImage = () => {
    UploadService.deleteImage(imageInfos[selectedImage] as any)
    setImageInfos(imageInfos.filter((v, i) => i != selectedImage))
  }

  return (
    <div>
    {imageInfos.map((image, index) => (
      <img className="qrCode"
        src={`${window.location.href}/qr-codes/${image}`} 
        key={index} alt="info"
        onClick={() => setSelectedImage(index)}>
        </img>
    ))}
    {selectedImage != -1 ? (
        <div id="cover"
        onClick={() => setSelectedImage(-1)}>
          <button className="button-23"  onClick={() => deleteImage()} >delete</button>
          <div id="box">
            <img
            className="selected" 
            src={`${window.location.href}/qr-codes/${imageInfos[selectedImage]}`}>
            </img>
          </div>
        </div>

    ) : null}
    </div>
  );
};

export default ImageViewer;