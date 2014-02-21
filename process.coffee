#{{{1 utility
fs = require("fs")

#{{{2 iterate through a file
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

#{{{2 parse a date/time
parseDate = (str) ->
  f = (n) -> + str.slice(n, n+2)
  new Date(2000 + (f 2), (f 5), (f 8), (f 11), (f 14))

#{{{1 extract parkometer positions
parkomat = {}
parkomatBound =
  latMax: -1000
  lngMax: -1000
  latMin: 1000
  lngMin: 1000
do ->
  for line in String(fs.readFileSync("parkomat.csv")).split("\n")
    !line.replace /POINT .([^ ]*?) ([^ ]*?)\),[^,]*,([^,]*),/, (_, lng, lat, id) ->
      parkomatBound.latMax = Math.max parkomatBound.latMax, +lat
      parkomatBound.lngMax = Math.max parkomatBound.lngMax, +lng
      parkomatBound.latMin = Math.min parkomatBound.latMin, +lat
      parkomatBound.lngMin = Math.min parkomatBound.lngMin, +lng

      parkomat[id] =
        id: +id
        lat: +lat
        lng: +lng
        current: 0
        sampling: 0
        max: 0
  
  console.log parkomatBound
  
  
#{{{1 histogram data
histogram = {}
histogramPrecision = 15*60*1000
histInc = (i, n) -> histogram[i] = (histogram[i] || 0) + n

#{{{1 iterate through a file
largefile = true
if largefile
  filename = "../parkomat-transaktioner-2013.csv"
else
  filename = "id-tlRecordID-tlPDM-tlPayDateTime-tlExpDateTime.csv"


onpark = (fn) ->
  count = 0
  foreachLineInFile filename, (line) ->
    return fn() if line == undefined
    return if line == "tlRecordID,tlPDM,tlPayDateTime,tlExpDateTime"

    if largefile
      [record, pdm, paydate, expdate] = line.split ","
    else
      [id, record, pdm, paydate, expdate] = line.split ","
    paydate = +(parseDate paydate)/60000
    expdate = +(parseDate expdate)/60000
    length = (expdate - paydate)
    if length > 14*24*60
      console.log line
      return
    if (count % 10000) == 0
      console.log new Date(paydate*60000), count, ends.length, length, parkomat[pdm]
    ++count
    return if !parkomat[pdm]
    return if length <= 0
    fn
      start: paydate
      end: expdate
      parkomat: parkomat[pdm]

#{{{1

doStart = (obj) ->
  ++obj.parkomat.current
  obj.parkomat.max = Math.max(obj.parkomat.current, obj.parkomat.max)

doEnd = (obj) ->
  --obj.parkomat.current

done = ->
  console.log "writing parkomat.json"
  fs.writeFile "parkomat.json", JSON.stringify {parkomat: parkomat, samples: samples}, null, "  "

  

ends = []
time = undefined
t = undefined
thour = undefined
samples = 0
onpark (obj) ->
  return done() if !obj
  thour = time = obj.start if time == undefined
  if time > thour + 60
    thour += 60
    ++samples
    p.sampling += p.current for _, p of parkomat
  ends.push obj
  if time < obj.start
    time = obj.start
    i = 0
    while i < ends.length
      if ends[i].end <= time
        doEnd ends[i]
        ends[i] = ends[ends.length - 1]
        ends.pop()
      ++i
  doStart obj

#{{{1 run throught the file and make histogram/map
if false
  
  foreachLineInFile filename, (line) ->
    if (count % 10000) == 0
      console.log count
    ++count
    return if line == "tlRecordID,tlPDM,tlPayDateTime,tlExpDateTime"
    if line == undefined
      done()
      return
    if largefile
      [record, pdm, paydate, expdate] = line.split ","
    else
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
    str = ""
    for a, b of histogram
      #console.log "#{new Date(a*histogramPrecision)}, #{b}"
      str += "#{a},#{b}\n"
      #console.log "#{a},#{b}"
    fs.writeFile "../parko.xy", str
    ###
    console.log histogram
    max = 0
    for _, n of histogram
      max = Math.max(max, n)
    console.log "max", max
    ###
