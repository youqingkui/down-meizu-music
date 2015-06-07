#!/usr/bin/env node
// Generated by CoffeeScript 1.8.0
(function() {
  var Music, argv, async, cheerio, fs, music, request, url;

  request = require("request");

  async = require("async");

  cheerio = require("cheerio");

  fs = require("fs");

  argv = require('optimist').argv;

  Music = (function() {
    function Music(url) {
      this.url = url;
      this.songs = [];
      this.album = 'youqing';
      this.albumImgUrl = '';
      this.artist = 'youqing';
      this.headers = {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.81 Safari/537.3'
      };
    }

    Music.prototype.getUrlInfo = function(cb) {
      var getJSON, getSongsInfo, self;
      self = this;
      return async.waterfall([
        getJSON = function(callback) {
          var op;
          op = {
            url: self.url,
            headers: self.headers
          };
          return request.get(op, function(err, res, body) {
            var $, album, arr, describe, imgUrl, jsonSongs, songs_text, tmp, url;
            if (err) {
              return console.log(err);
            }
            $ = cheerio.load(body);
            imgUrl = $(".special img");
            album = $("h4.name");
            describe = $(".describe").first();
            if (imgUrl.length) {
              self.albumImgUrl = imgUrl.attr('src');
            }
            if (album.length) {
              self.album = album.text();
            }
            if (describe.length) {
              self.artist = $(describe).text();
            } else {
              songs_text = $('script:contains("url")').text();
              if (!songs_text) {
                return console.log("没有发现分享里面的东西1");
              }
              self.album = $(".singer").text();
              url = self.getSingSongUrl(songs_text);
              arr = [];
              tmp = {};
              tmp.title = $("h4.name").text();
              tmp.url = url;
              arr.push(tmp);
              return callback(null, arr);
            }
            songs_text = $('script:contains("songs")').text();
            if (!songs_text) {
              return console.log("没有发现专辑分享里面的东西2");
            }
            jsonSongs = eval(songs_text);
            return callback(null, jsonSongs);
          });
        }, getSongsInfo = function(songs, callback) {
          songs.forEach(function(item) {
            var tmp;
            tmp = {};
            tmp.title = item.title;
            tmp.url = item.url;
            return self.songs.push(tmp);
          });
          return cb();
        }
      ]);
    };

    Music.prototype.getSingSongUrl = function(text) {
      var arr1, url;
      arr1 = text.split('"');
      url = arr1[7];
      return url;
    };

    Music.prototype.getSongUrl = function(cb) {
      var bashUrl, self;
      self = this;
      bashUrl = 'http://music.meizu.com';
      return async.eachSeries(self.songs, function(item, callback) {
        var url;
        url = bashUrl + item.url;
        return request.get(url, function(err, res, body) {
          var data;
          if (err) {
            return console.log(err);
          }
          data = JSON.parse(body);
          if (data.code !== 200) {
            return console.log("获取下载错误200", data);
          }
          item.downUrl = data.value.url;
          item.ext = data.value.format;
          return callback();
        });
      }, function() {
        return cb();
      });
    };

    Music.prototype.downSongs = function(cb) {
      var self;
      self = this;
      return async.eachSeries(self.songs, function(item, callback) {
        return self.downSong(item, callback);
      }, function() {
        return console.log("all down");
      });
    };

    Music.prototype.downSong = function(info, cb) {
      var self, writeSong;
      self = this;
      writeSong = fs.createWriteStream(self.album + '/' + info.title + '.' + info.ext);
      return request.get(info.downUrl).on('response', function(res) {
        console.log(res.statusCode);
        if (res.statusCode === 200) {
          return console.log("连接下载歌曲" + info.title + "成功");
        }
      }).on("error", function(err) {
        console.log("" + self.album + " " + info.title + "  " + info.downUrl + " down error: " + err);
        return console.log("下载歌曲失败");
      }).on('end', function() {
        console.log("" + self.album + " " + info.title + " 歌曲下载成功");
        console.log(".................................\n");
        return cb();
      }).pipe(writeSong);
    };

    Music.prototype.createAlbumFolder = function(cb) {
      var self;
      self = this;
      if (!fs.existsSync(self.album)) {
        fs.mkdirSync(self.album);
      }
      return cb();
    };

    Music.prototype.downAlbumImg = function(cb) {
      var ext, extArr, self, writeImg;
      self = this;
      extArr = self.albumImgUrl.split('.');
      ext = extArr[extArr.length - 1];
      writeImg = fs.createWriteStream(self.album + '/' + self.album + '.' + ext);
      return request.get(self.albumImgUrl).on('response', function(res) {
        console.log(res.statusCode);
        if (res.statusCode === 200) {
          return console.log('连接下载歌曲专辑图片成功', self.albumImgUrl);
        }
      }).on("error", function(err) {
        console.log("" + self.album + "  " + self.albumImgUrl + " down error: " + err);
        return console.log("下载歌曲专辑图片失败失败");
      }).on('end', function() {
        console.log("" + self.album + " " + self.albumImgUrl + " 【专辑图片】下载成功");
        console.log(".................................\n");
        return cb();
      }).pipe(writeImg);
    };

    Music.prototype.doTask = function() {
      var self;
      self = this;
      return async.series([
        function(cb) {
          return self.getUrlInfo(cb);
        }, function(cb) {
          return self.createAlbumFolder(cb);
        }, function(cb) {
          return self.downAlbumImg(cb);
        }, function(cb) {
          return self.getSongUrl(cb);
        }, function(cb) {
          return self.downSongs(cb);
        }
      ]);
    };

    return Music;

  })();

  url = argv._[0];

  if (!url) {
    console.log("需要输入从魅族音乐分享出来的专辑或单曲URL");
  } else {
    music = new Music(url);
    music.doTask();
  }

}).call(this);

//# sourceMappingURL=app.js.map
