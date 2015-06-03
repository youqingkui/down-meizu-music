request = require("request")
async = require("async")
cheerio = require("cheerio")
fs = require("fs")


class Music
  constructor: (@url) ->
    @songs = []
    @album = 'youqing'
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
      console.log "................................."
      console.log "#{self.album}  #{info.downUrl}"
      console.log(res.statusCode)
      if res.statusCode is 200
        console.log '连接下载歌曲成功'

    .on "error", (err) ->
      console.log "#{self.album}  #{info.downUrl} down error: #{err}"
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



music = new Music('http://music.meizu.com/share/distribute.do?style=2&id=2406399&type=2&source=2&token=0f72e10819af1f35f9a90a053b9cc9f3')
async.series [
  (cb) ->
    music.getUrlInfo cb

  (cb) ->
    music.createAlbumFolder cb

  (cb) ->
    music.getSongUrl cb


  (cb) ->
    music.downSongs cb


]



