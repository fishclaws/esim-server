import { BadRequestException, Controller, Delete, FileTypeValidator, Get, HttpStatus, MaxFileSizeValidator, Param, ParseFilePipe, ParseFilePipeBuilder, Post, Query, Res, UploadedFile, UseInterceptors } from '@nestjs/common';
import { AppService } from './app.service';
import { FileInterceptor } from '@nestjs/platform-express';
import QrScanner from 'qr-scanner';
import Jimp from 'jimp';
var QrCode = require('qrcode-reader');
import { Response } from 'express';
import multer from 'multer';
import { buffer } from 'stream/consumers';
import { spath } from './values';
var path = require('path');
var moment = require('moment');

import jsQR from "jsqr";


@Controller()
export class AppController {
  constructor(private readonly appService: AppService) { }

  @Get(spath + '/esims')
  getFiles(): string {
    return this.appService.getFiles();
  }

  @Get(spath + '/qr-codes/:file_name')
  serveFile(@Param('file_name') filename: string, @Res() res: Response) {
    if (filename.includes("..") || (!filename.includes(".png") && !filename.includes("jpg"))) {
      res.status(HttpStatus.BAD_REQUEST).send();
      return
    }
    res.sendFile(path.resolve("qr-codes/" + filename))
  }

  @Delete(spath + '/qr-codes/:file_name')
  deleteFile(@Param('file_name') filename: string, @Res() res: Response) {
    if (filename.includes("..") || !filename.includes(".png")) {
      res.status(HttpStatus.BAD_REQUEST).send();
      return
    }
    return this.appService.deleteFile(path.resolve("qr-codes/" + filename))
  }


  @Post('upload')
  @UseInterceptors(FileInterceptor('file'))
  uploadFile(@UploadedFile(
    new ParseFilePipeBuilder()
      .addFileTypeValidator({
        fileType: 'jpeg|png',
      })
      .addMaxSizeValidator({
        maxSize: 1000 * 600
      })
      .build({
        errorHttpStatusCode: HttpStatus.UNPROCESSABLE_ENTITY
      }),
  ) file: Express.Multer.File, @Res() res: Response) {


    const files = this.appService.getFiles()
    if (files.length > 10000) 
      res.status(HttpStatus.BAD_REQUEST).send();

    const FormData = require('form-data');
    const formData = new FormData();
    formData.append('file', Buffer.from(file.buffer), file.originalname);

    Jimp.read(file.buffer, function (err, image) {
      if (err) {
        console.error(err);
        // TODO handle error
      }

      
      const code = jsQR(image.bitmap.data as any, image.bitmap.width, image.bitmap.height);
      if (!code) {
        res.status(HttpStatus.BAD_REQUEST).send({
                message: "Not a valid QR Code"
              });
        return
      }
      console.log(code.data)
      if (!code.data.includes("rsp.truphone.com")) {
        res.status(HttpStatus.BAD_REQUEST).send({
                message: "Not a valid QR Code"
              });
        return
      }
      image.write(`qr-codes/${moment().format('yyyy-mm-dd-hh-mm-ss')}.png`)
      res.status(HttpStatus.CREATED).send();
      // var qr = new QrCode();
      // qr.callback = function (err, value) {
      //   if (err) {
      //     console.error(err);
      //     res.status(HttpStatus.BAD_REQUEST).send({
      //       message: "Not a valid QR Code"
      //     });
      //     return
      //   } else {
      //     image.write(`qr-codes/${moment().format('yyyy-mm-dd-hh-mm-ss')}.png`)
      //   }
      //   console.log(value.result);
      //   console.log(value);
      //   res.status(HttpStatus.CREATED).send();
      // };
      // qr.decode(image.bitmap);
      // check if valid url...
      // save image


    });
  }
}
