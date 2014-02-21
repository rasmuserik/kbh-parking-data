fs = require("fs")

foreachLineInFile = (filename, fn) ->
  stream = fs.createReadStream(filename)
  readbuf = ""
  stream.on "data", (data) ->
    stream.pause()
    readbuf += data
    lines = readbuf.split "\n"
    readbuf = lines[lines.length - 1]
    lines = lines.slice(0, -1)
    fn(line) for line in lines
    stream.resume()

  stream.on "end", ->
    fn(readbuf) if readbuf
    fn()
  stream.on "error", -> throw error

parseDate = (str) ->
  f = (n) -> + str.slice(n, n+2)
  new Date(2000 + (f 2), (f 5), (f 8), (f 11), (f 14))
  

#{{{1 extract parkometer positions
parkomat = {}
for line in String(fs.readFileSync("parkomat.csv")).split("\n")
  !line.replace /POINT .([^ ]*?) ([^ ]*?)\),[^,]*,([^,]*),/, (_, lat, lng, id) ->
    parkomat[id] = [lat, lng]

histogram = {}
histogramPrecision = 15*60*1000
histInc = (i, n) -> histogram[i] = (histogram[i] || 0) + n

foreachLineInFile "id-tlRecordID-tlPDM-tlPayDateTime-tlExpDateTime.csv", (line) ->
  if line == undefined
    done()
    return
  return done() if line == undefined
  [id, record, pdm, paydate, expdate] = line.split ","
  paydate = +parseDate paydate
  expdate = +parseDate expdate
  length = (expdate - paydate)/60000
  return if !parkomat[pdm]
  return if length <= 0
  paydate /= histogramPrecision
  expdate /= histogramPrecision
  start = Math.floor paydate
  end = Math.ceil expdate
  for i in [start..end]
    histInc(i, 1)
  #histInc(Math.floor(paydate), -(paydate - start))
  #histInc(Math.floor(expdate), -(end - expdate))

done = ->
  for a, b of histogram
    #console.log "#{new Date(a*histogramPrecision)}, #{b}"
    console.log "#{a},#{b}"
  ###
  console.log histogram
  max = 0
  for _, n of histogram
    max = Math.max(max, n)
  console.log "max", max
  ###
