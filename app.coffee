request = require("request")
async = require("async")
cheerio = require("cheerio")
fs = require("fs")


Music = (@url) ->
  @songs = []
  @album = 'youqing'
  @artist = 'youqing'
  @song_name = ''
  @image_url = ''
  @song_url = ''
  @songDownUrl = ''

  return


Music::getUrlInfo = () ->

  self = @
  async.series [
    (cb) ->
      request.get self.url, (err, res, body) ->
        if err
          return console.log err

        $ = cheerio.load(body)
        songs_text = $('script:contains("songs")').text()
        # todo oh， 这里可能存在安全隐患，暂时没有找到替代
        self.songs = eval(songs_text)
        cb()

    (cb) ->
      async.eachSeries @songs, (item, callback) ->
        self.album = item.url
        self.artist = item.artist
        self.image_url = item.image
        self.song_url = item.url
        self.song_name = item.title
        self.createAlbumFolder(callback)

  ]




Music::createAlbumFolder = (cb) ->
  # 创建专辑文件夹

  self = @
  unless fs.existsSync(self.album)
    fs.mkdirSync(self.album)

  self.downAlbumImage(cb)


Music::downAlbumImage = (cb) ->
  # 下载专辑图片

  self = @
  writeImg = fs.createWriteStream(self.album + '/' + self.album + ".jpg")
  request.get self.image_url

  .on 'response', (res) ->
    console.log "................................."
    console.log "#{self.album}  #{self.image_url}"
    console.log(res.statusCode)
    if res.statusCode is 200
      console.log '连接下载专辑图片成功'

  .on "error", (err) ->
    console.log "#{self.album}  #{self.image_url} down error: #{err}"
    return console.log "下载专辑图片失败"

  .on 'end', () ->
    console.log "#{self.album} 图片下载成功"
    console.log ".................................\n"
    cb()
  .pipe(writeImg)

Music::getSongUrl = (cb) ->
  # 获取下载歌曲链接

  self = @
  host = 'http://music.meizu.com'
  comUrl = host + self.song_url
  request.get comUrl, (err, res, body) ->
    if err
      return console.log err

    data = JSON.parse(body)
    if data.code != 200
      return "获取下载错误200"

    self.songDownUrl = data.value.url
    cb()

Music::downSong = (cb) ->
  # 下载歌曲

  self = @
  writeSong = fs.createWriteStream(self.album + '/' + self.song_name + ".m4a")
  request.get self.downSong()

  .on 'response', (res) ->
    console.log "................................."
    console.log "#{self.album}  #{self.image_url}"
    console.log(res.statusCode)
    if res.statusCode is 200
      console.log '连接下载歌曲成功'

  .on "error", (err) ->
    console.log "#{self.album}  #{self.image_url} down error: #{err}"
    return console.log "下载专歌曲失败"

  .on 'end', () ->
    console.log "#{self.album} 歌曲下载成功"
    console.log ".................................\n"
    cb()
  .pipe(writeSong)
















