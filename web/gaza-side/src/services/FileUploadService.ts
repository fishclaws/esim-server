import http from "../http-common";

const upload = (file: File, onUploadProgress: any): Promise<any> => {
  let formData = new FormData();

  formData.append("file", file);

  return http.post("/upload", formData, {
    headers: {
      "Content-Type": "multipart/form-data",
    },
    onUploadProgress,
  });
};

const getFiles = () : Promise<any> => {
  console.log(window.location.href)
  return http.get(window.location.href + "/esims");
};

const deleteImage = (filename: string) : Promise<any> => {
  return http.delete(window.location.href + "/qr-codes/" + filename)
}

const FileUploadService = {
  upload,
  getFiles,
  deleteImage
};

export default FileUploadService;