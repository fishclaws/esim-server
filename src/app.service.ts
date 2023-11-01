import { Injectable } from '@nestjs/common';
const fs = require('fs');

@Injectable()
export class AppService {
  getFiles(): string {
    return fs.readdirSync('qr-codes')
  }

  deleteFile(filePath) {
    fs.unlinkSync(filePath);
  }
}
