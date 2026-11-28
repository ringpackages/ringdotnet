# CodeHollow.FeedReader: RSS and Atom feeds read from text (no download): the feed, its items, dates, categories, the feed type and the feeds that an HTML page announces
load "pkg.ring"
pkgUse("feedreader",[["CodeHollow.FeedReader","1.2.6"]],[["CodeHollow.FeedReader.dll",["CodeHollow.FeedReader","CodeHollow.FeedReader.Feeds"]]])
pkgImport("feedreader","CodeHollow.FeedReader.dll","CodeHollow.FeedReader")
pkgImport("feedreader","CodeHollow.FeedReader.dll","CodeHollow.FeedReader.Feeds")

cRss = '<?xml version="1.0" encoding="UTF-8"?><rss version="2.0"><channel>' +
	'<title>Ring News</title><link>https://ring.example.com/</link><description>News about Ring</description><language>en</language>' +
	'<item><title>Ring 1.28 is out</title><link>https://ring.example.com/128</link><description>The new version</description>' +
	'<pubDate>Mon, 06 May 2024 07:08:09 GMT</pubDate><author>ann@example.com (Ann)</author><category>release</category><category>ring</category><guid>id-128</guid></item>' +
	'<item><title>RingDotNet</title><link>https://ring.example.com/dotnet</link><description>Ring calls .NET</description>' +
	'<pubDate>Tue, 07 May 2024 10:00:00 GMT</pubDate><guid>id-dotnet</guid></item>' +
	'</channel></rss>'

oReader = new FeedReader()
oFeed = oReader.ReadFromString(cRss)
dnAssert("the feed title",oFeed.Title,"Ring News")
dnAssert("the feed link",oFeed.Link,"https://ring.example.com/")
dnAssert("the feed description",oFeed.Description,"News about Ring")
dnAssert("the feed language",oFeed.Language,"en")
dnAssert("the feed type",oFeed.Type,"Rss_2_0")
aItems = oFeed.Items.toList()
dnAssert("the number of items",len(aItems),2)
dnAssert("the item title",aItems[1].Title,"Ring 1.28 is out")
dnAssert("the item link",aItems[1].Link,"https://ring.example.com/128")
dnAssert("the item text",aItems[1].Description,"The new version")
dnAssert("the item identifier",aItems[1].Id,"id-128")
dnAssert("the item author",substr(aItems[1].Author,"Ann") > 0,True)
dnAssert("the item date: year",aItems[1].PublishingDate.Year,2024)
dnAssert("the item date: month",aItems[1].PublishingDate.Month,5)
dnAssert("the item date: day",aItems[1].PublishingDate.Day,6)
dnAssert("the item categories",aItems[1].Categories.Count,2)
dnAssert("the second item title",aItems[2].Title,"RingDotNet")

# an Atom feed
cAtom = '<?xml version="1.0" encoding="utf-8"?><feed xmlns="http://www.w3.org/2005/Atom"><title>Atom Ring</title><id>urn:uuid:1</id>' +
	'<link href="https://atom.example.com/"/><updated>2024-05-06T07:08:09Z</updated>' +
	'<entry><title>First entry</title><id>urn:uuid:2</id><link href="https://atom.example.com/1"/><updated>2024-05-06T07:08:09Z</updated><summary>Short</summary></entry></feed>'
oAtom = oReader.ReadFromString(cAtom)
dnAssert("an Atom feed",oAtom.Type,"Atom")
dnAssert("the Atom title",oAtom.Title,"Atom Ring")
dnAssert("the Atom entries",len(oAtom.Items.toList()),1)
dnAssert("the entry title",oAtom.Items.toList()[1].Title,"First entry")

# the feeds that an HTML page announces
cHtml = '<html><head><link rel="alternate" type="application/rss+xml" title="News" href="/feed.xml"><link rel="alternate" type="application/atom+xml" href="https://other.example.com/atom"></head><body></body></html>'
aLinks = oReader.ParseFeedUrlsFromHtml(cHtml).toList()
dnAssert("two feeds were announced",len(aLinks),2)
dnAssert("the first feed address",aLinks[1].Url,"/feed.xml")
dnAssert("the first feed title",aLinks[1].Title,"News")
dnAssert("an address is made absolute (with its port)",oReader.GetAbsoluteUrl("https://ring.example.com/page/"),"https://ring.example.com:443/page/")

# text that is not a feed is an error
lError = 0
try
	oReader.ReadFromString("this is not a feed")
catch
	lError = 1
done
dnAssert("text that is not a feed raises an error",lError,1)

dnTestSummary()
