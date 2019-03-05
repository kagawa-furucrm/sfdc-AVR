# はじめに

*(Mac環境の記事ですが、Windows環境も同じ手順になります。環境依存の部分は読み替えてお試しください。)*

この記事を最後まで読むと、次のことができるようになります。

- Salesforceの添付ファイルについて理解する
- Apexを使って実装する

## 目的

関連リストに紐づく添付ファイルは、親レコードと参照関係となるため、親レコードの状態に関係なく操作(作成/編集/削除)ができてしまう。例えば、承認プロセスのレコードロック状態においても添付ファイルの更新が可能。`ある条件`を満たした場合は、添付ファイルの操作を制限したい(入力規則のようなイメージ)。

*(後にSalesforce ClassicとLightning Experienceで添付ファイルの保存先が異なることを知り、無理やりLightning Experienceでも動くようにしました。そのためコードは美しくありません。)*

`アプリの仕様`

条件を満たした場合は、添付ファイルの操作(作成/編集/削除)を制限します。

|        項目名         |               説明               |
|-----------------------|----------------------------------|
| AVR No.               | レコードの連番                   |
| IsActive              | アクティブ設定                   |
| Memo                  | メモ                             |
| SObject               | 添付ファイルを制限するSObject名  |
| SOQL WHERE Clause     | 添付ファイルを制限する条件       |
| Excluded Profile      | 制限を対象外にするプロファイル名 |
| Excluded Public Group | 制限を対象外にする公開グループ名 |
| Excluded User         | 制限を対象外にするユーザ名       |
| Error Message         | エラーメッセージ                 |

`イメージ画像`

| 設定画面                                                                                                                                                              |
| :-------------------------------------------------------------------------------------------------------------------------------------------------------------------: |
| <img width="500" alt="スクリーンショット 2019-03-05 21.13.35.png" src="https://qiita-image-store.s3.amazonaws.com/0/326996/2b2aa73e-d7bc-acf8-e34a-7afe3ad5c760.png"> |

| 制限画面                                                                                                                                                              |
| :-------------------------------------------------------------------------------------------------------------------------------------------------------------------: |
| <img width="500" alt="スクリーンショット 2019-03-05 21.02.34.png" src="https://qiita-image-store.s3.amazonaws.com/0/326996/2ab1c87e-0ec5-cf9e-85c0-100dcebdfb2a.png"> |

# 関連する記事

- [API Attachment](https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_objects_attachment.htm)
- [API ContentDocument](https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_objects_contentdocument.htm)
- [API ContentDocumentLink](https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/sforce_api_objects_contentdocumentlink.htm)

# 実行環境

|     環境     |    Ver.    |
|--------------|------------|
| macOS Mojave | 10.14.3    |
| Salesforce   | Winter '18 |

# ソースコード

実際に実装内容やソースコードを追いながら読むとより理解が深まるかと思います。是非ご活用ください。

[GitHub](https://github.com/nsuhara/sfdc-AVR.git)

# ポイント

1. Salesforce ClassicとLightning Experienceでは、添付ファイルの保存先が異なる。Salesforce Classicは`Attachment`、Lightning Experienceは`ContentDocument`に保存される。

1. `ContentDocument`は親レコードの参照項目をもっていないため、`ContentDocumentLink`から参照する。

1. `ContentDocumentLink`は`ContentDocument`の後に作成される。

1. `ContentDocument`(Insert)のエラーメッセージ設定は、`FinalException`が発生するため、Insertは`ContentDocumentLink`のTriggerイベントで判断し、Update/Deleteは`ContentDocument`のTriggerイベントで判断する。

1. (参考) 親レコードの`CombinedAttachments`を参照すると`Attachment`と`ContentDocument`の両方がとれる。

	```
	SELECT Id, Name, (SELECT Id, Title FROM CombinedAttachments) FROM Opportunity
	```

1. (参考) `Attachment`と`ContentDocument`は種別で見分けができる。添付ファイルは`Attachment`、ファイルは`ContentDocument`となる。

	<img width="400" alt="スクリーンショット 2019-03-05 23.32.17.png" src="https://qiita-image-store.s3.amazonaws.com/0/326996/8f5af6eb-046d-19a5-7ecc-007e5a4d3f88.png">

# 動作検証

添付ファイルを制限する条件を設定する(商談のフェーズが`Closed Won`の場合は、添付ファイルの操作を制限する)。

<img width="500" alt="スクリーンショット 2019-03-05 21.13.35.png" src="https://qiita-image-store.s3.amazonaws.com/0/326996/2b2aa73e-d7bc-acf8-e34a-7afe3ad5c760.png">

レコードを作成および添付ファイルを設定して条件を満たす状態にする(フェーズを`Closed Won`に設定する)。

<img width="500" alt="スクリーンショット 2019-03-05 21.01.29.png" src="https://qiita-image-store.s3.amazonaws.com/0/326996/3dd0d60c-9082-a74a-d630-1f432a2ebf36.png">

添付ファイルを削除する

<img width="500" alt="スクリーンショット 2019-03-05 21.02.34.png" src="https://qiita-image-store.s3.amazonaws.com/0/326996/2ab1c87e-0ec5-cf9e-85c0-100dcebdfb2a.png">
