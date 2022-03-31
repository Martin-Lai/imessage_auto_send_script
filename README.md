# imessage_auto_send_script

此程式可自動發訊息給指定手機號碼，並輸出所有成功失敗的號碼(csv)，若手機號碼為android sent為fail，若為ios但沒有網路delivered為fail。 程式透過讀取message內部的db來判斷訊息成功或失敗，故需關閉SIP。 經過實測，大量發送廣告會遭受apple官方的懲處，故無法作為替代簡訊廣告之方法。

This project can send messsage to phone numbers, and output the result by csv. If the number is android, sent column will be fail, ios but not have internet the delivered column will be fail. This project judge the success or fail of the message by reading the db of the message program, so you need to close SIP. Sending a large number of advertisements will be punished by Apple and can't be used as an alternative to SMS advertisements.
