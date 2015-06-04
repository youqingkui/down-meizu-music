request = require("request")
async = require("async")
cheerio = require("cheerio")
fs = require("fs")
argv = require('optimist').argv


class Music
  constructor: (@url) ->
    @songs = []
    @album = 'youqing'
    @albumImgUrl = ''
    @artist = 'youqing'
    @headers = {
      'User-Agent':'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.81 Safari/537.3'
    }


  getUrlInfo:(cb) ->
    self = @
    async.waterfall [
      getJSON = (callback) ->
        op = {
          url:self.url
          headers:self.headers

        }
        request.get op, (err, res, body) ->
          return console.log err if err

          $ = cheerio.load(body)
          imgUrl = $(".special img")
          album = $("h4.name")
          describe = $(".describe").first()
          if imgUrl.length
            self.albumImgUrl = imgUrl.attr('src')

          if album.length
            self.album = album.text()

          if describe.length
            self.artist = $(describe).text()


          songs_text = $('script:contains("songs")').text()
          # todo oh， 这里可能存在安全隐患，暂时没有找到替代
          jsonSongs = eval(songs_text)
          callback(null, jsonSongs)


      getSongsInfo = (songs, callback) ->
        songs.forEach (item) ->
          tmp = {}
          tmp.title = item.title
          tmp.url = item.url
          self.songs.push tmp

        cb()

    ]

  getSongUrl:(cb) ->
    self = @
    bashUrl = 'http://music.meizu.com'
    async.eachSeries self.songs, (item, callback) ->
      url = bashUrl + item.url
      request.get url, (err, res, body) ->
        return console.log err if err

        data = JSON.parse(body)
        if data.code != 200
          return console.log "获取下载错误200", data

        item.downUrl = data.value.url
        item.ext = data.value.format
        callback()

    ,() ->
      cb()


  downSongs:(cb) ->
    self = @
    async.eachSeries self.songs, (item, callback) ->
      self.downSong(item, callback)

    ,() ->
      console.log "all down"

  downSong:(info, cb) ->
    self = @
    writeSong = fs.createWriteStream(self.album + '/' + info.title + '.' + info.ext)
    request.get info.downUrl

    .on 'response', (res) ->
#      console.log "................................."
#      console.log "#{self.album}  #{info.downUrl}"
      console.log(res.statusCode)
      if res.statusCode is 200
        console.log "连接下载歌曲#{info.title}成功"

    .on "error", (err) ->
      console.log "#{self.album} #{info.title}  #{info.downUrl} down error: #{err}"
      return console.log "下载歌曲失败"

    .on 'end', () ->
      console.log "#{self.album} #{info.title} 歌曲下载成功"
      console.log ".................................\n"
      cb()
    .pipe(writeSong)


  createAlbumFolder:(cb) ->
    self = @
    unless fs.existsSync(self.album)
      fs.mkdirSync(self.album)

    cb()


  downAlbumImg:(cb) ->
    self = @
    extArr = self.albumImgUrl.split('.')
    ext = extArr[extArr.length - 1]
    writeImg = fs.createWriteStream(self.album + '/' + self.album + '.' + ext)

    request.get self.albumImgUrl

    .on 'response', (res) ->
#      console.log "................................."
#      console.log "#{self.album}  #{self.albumImgUrl}"
      console.log(res.statusCode)
      if res.statusCode is 200
        console.log '连接下载歌曲专辑图片成功', self.albumImgUrl

    .on "error", (err) ->
      console.log "#{self.album}  #{self.albumImgUrl} down error: #{err}"
      return console.log "下载歌曲专辑图片失败失败"

    .on 'end', () ->
      console.log "#{self.album} #{self.albumImgUrl} 【专辑图片】下载成功"
      console.log ".................................\n"
      cb()
    .pipe(writeImg)


  doTask:() ->
    self = @
    async.series [
      (cb) ->
        self.getUrlInfo cb

      (cb) ->
        self.createAlbumFolder cb

      (cb) ->
        self.downAlbumImg cb

      (cb) ->
        self.getSongUrl cb


      (cb) ->
        self.downSongs cb


    ]




#music = new Music('http://music.meizu.com/share/distribute.do?style=2&id=2318991&type=2&source=2&token=3a3322513c2750ad80c5149adb3795d6')
#music.doTask()
#console.log argv
url = argv._[0]
if not url
  console.log "需要输入从魅族音乐分享出来的专辑URL"

else
  music = new Music(url)
  music.doTask()




