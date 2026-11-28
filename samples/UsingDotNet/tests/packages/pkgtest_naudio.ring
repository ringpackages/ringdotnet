# NAudio.Core: wave formats, a generated sine wave, a WAV file written to memory and read back (no sound device is used)
load "pkg.ring"
pkgUse("naudio",[["NAudio.Core","2.2.1"]],[["NAudio.Core.dll",["NAudio.Wave","NAudio.Wave.SampleProviders"]]])
pkgImport("naudio","NAudio.Core.dll","NAudio.Wave")
pkgImport("naudio","NAudio.Core.dll","NAudio.Wave.SampleProviders")
dnImport("System.IO")

# the default format: CD quality
oCd = new WaveFormat()
dnAssert("the default sample rate",oCd.SampleRate,44100)
dnAssert("the default bits",oCd.BitsPerSample,16)
dnAssert("the default channels",oCd.Channels,2)
dnAssert("bytes in a block",oCd.BlockAlign,4)
dnAssert("bytes in a second",oCd.AverageBytesPerSecond,176400)

oMono = (new WaveFormat).@New([ :rate = 8000, :bits = 16, :channels = 1 ])
dnAssert("a mono format: rate",oMono.SampleRate,8000)
dnAssert("a mono format: block",oMono.BlockAlign,2)
dnAssert("a mono format: bytes in a second",oMono.AverageBytesPerSecond,16000)
dnAssert("the same format is equal",oMono.Equals((new WaveFormat).@New([ :rate = 8000, :bits = 16, :channels = 1 ])),1)
dnAssert("another format is not equal",oMono.Equals(oCd),0)

oFloat = (new WaveFormat).CreateIeeeFloatWaveFormat(22050,1)
dnAssert("a float format: bits",oFloat.BitsPerSample,32)
dnAssert("a float format: the encoding",oFloat.Encoding,"IeeeFloat")

# one second of a 440 Hz sine wave at 8000 samples a second: 8000 samples
oSine = (new SignalGenerator).@New([ :sampleRate = 8000, :channel = 1 ])
oSine.Frequency = 440
oSine.Gain = 0.5
dnAssert("the generator frequency",oSine.Frequency,440)
dnAssert("the generator format",oSine.WaveFormat.SampleRate,8000)
oOne = new OffsetSampleProvider(oSine)
oOne.TakeSamples = 8000
oPcm = oOne.ToWaveProvider16()
dnAssert("the 16 bit provider",oPcm.WaveFormat.BitsPerSample,16)

# a WAV file in memory
oStream = new MemoryStream()
oWriter = new WaveFileWriter(oStream,oMono)
oPcmBuffer = dnNew("System.Byte[]",[16000])
nRead = oPcm.Read(oPcmBuffer,0,16000)
dnAssert("a second of 16 bit samples was read",nRead,16000)
oWriter.Write(oPcmBuffer,0,nRead)
oWriter.Flush()
dnAssert("the writer counts the data",oWriter.Length,16000)
dnAssert("the stream has a header and the data",oStream.Length > 16000,True)

oStream.Position = 0
oReader = new WaveFileReader(oStream)
dnAssert("read back: the length",oReader.Length,16000)
dnAssert("read back: the duration",oReader.TotalTime.TotalSeconds,1)
dnAssert("read back: the sample rate",oReader.WaveFormat.SampleRate,8000)

dnTestSummary()
