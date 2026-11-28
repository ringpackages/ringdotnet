# Telegram.Bot: the bot client (made from a token, no network), keyboards and the types of messages, users and chats; nothing is sent
load "pkg.ring"
pkgUse("telegrambot",[["Telegram.Bot","22.2.0"]],[["Telegram.Bot.dll",["Telegram.Bot","Telegram.Bot.Types","Telegram.Bot.Types.Enums","Telegram.Bot.Types.ReplyMarkups"]]])
pkgImport("telegrambot","Telegram.Bot.dll","Telegram.Bot")
pkgImport("telegrambot","Telegram.Bot.dll","Telegram.Bot.Types")
pkgImport("telegrambot","Telegram.Bot.dll","Telegram.Bot.Types.ReplyMarkups")
dnImport("System")

# the number before the colon of a token is the identifier of the bot
oBot = new TelegramBotClient("123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11")
dnAssert("the bot identifier",oBot.BotId,123456)
dnAssert("the default timeout is 100 seconds",oBot.Timeout.TotalSeconds,100)
oBot.Timeout = (new TimeSpan).FromSeconds(30)
dnAssert("a changed timeout",oBot.Timeout.TotalSeconds,30)

# a token that is not in the format is an error
lError = 0
try
	oBad = new TelegramBotClient("not a token")
catch
	lError = 1
done
dnAssert("a bad token raises an error",lError,1)

# an inline keyboard: buttons that send data back
oYes = (new InlineKeyboardButton).@New("Yes")
oYes.CallbackData = "answer:yes"
oLink = (new InlineKeyboardButton).@New("Ring")
oLink.Url = "https://ring-lang.github.io"
dnAssert("a button: the text",oYes.Text,"Yes")
dnAssert("a button: the data",oYes.CallbackData,"answer:yes")
dnAssert("a link button: the address",oLink.Url,"https://ring-lang.github.io")

# a reply keyboard
oKeyboard = new ReplyKeyboardMarkup()
oKeyboard.ResizeKeyboard = True
oKeyboard.OneTimeKeyboard = True
oKeyboard.InputFieldPlaceholder = "Choose one"
dnAssert("a keyboard: resize",oKeyboard.ResizeKeyboard,True)
dnAssert("a keyboard: one time",oKeyboard.OneTimeKeyboard,True)
dnAssert("a keyboard: the hint",oKeyboard.InputFieldPlaceholder,"Choose one")
oKey = (new KeyboardButton).@New("Share my location")
oKey.RequestLocation = True
dnAssert("a key button",oKey.Text,"Share my location")
dnAssert("a key that asks for the location",oKey.RequestLocation,True)

# the types of a conversation
oUser = new User()
oUser.Id = 777
oUser.FirstName = "Ann"
oUser.Username = "ann_ring"
oUser.IsBot = False
dnAssert("a user: the id",oUser.Id,777)
dnAssert("a user: the name",oUser.FirstName,"Ann")
dnAssert("a user: the user name",oUser.Username,"ann_ring")
dnAssert("a user is not a bot",oUser.IsBot,False)
oChat = new Chat()
oChat.Id = 555
oChat.Title = "Ring friends"
dnAssert("a chat: the id",oChat.Id,555)
dnAssert("a chat: the title",oChat.Title,"Ring friends")
oMessage = new Message()
oMessage.Chat = oChat
oMessage.From = oUser
oMessage.Text = "hello bot"
dnAssert("a message: the text",oMessage.Text,"hello bot")
dnAssert("a message: the chat",oMessage.Chat.Title,"Ring friends")
dnAssert("a message: the sender",oMessage.From.FirstName,"Ann")

dnTestSummary()
