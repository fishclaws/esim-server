import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { ServeStaticModule } from '@nestjs/serve-static';
import { join } from 'path';
import { spath } from './values';
@Module({
  imports: [
    // ServeStaticModule.forRoot({
    //   rootPath: __dirname + "/../qr-codes",
    //   renderPath: spath + "/qr-codes/*.png",
    //   //serveRoot: "*",
    //   serveStaticOptions: {
    //      index: false,
    //      extensions: ['png']
    //    },
    // }),
    ServeStaticModule.forRoot({
      rootPath: __dirname + "/../web/gaza-side/build",
      renderPath: spath,
      exclude: [spath + '/*']
    }),
    ServeStaticModule.forRoot({
      rootPath: __dirname + "/../web/esim/build",
      exclude: [spath + '/*']
    }),

  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
