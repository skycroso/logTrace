
#!/bin/sh
ECHO=`which echo`

#ワークファイル・ワーク変数
M_FILE_LIST="/tmp/fileList"
BACKUP_DIR="/tmp/projectBackup_`date "+%Y%m%d%H%M%S"`"
LASTTIME="/tmp/lastTime"
LASTTIME_BACKUP="/tmp/lastTimeBk"
PREFIX="DEBUG"
FLAG="METHOD_TRACE_LOG"
LINE_STR="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ECHO
ECHO $LINE_STR
ECHO
ECHO " Objective-C トレースログを埋めこむシェル"
ECHO "                      2016/02/28 croso"
ECHO
ECHO $LINE_STR

####################################################
#
# 終了処理
#
FINISH() {
	#.mファイルリストを削除する
	RM -fr $M_FILE_LIST
	ECHO "終了します"
	exit;
}

####################################################
#
# 前回処理が残っているかチェック
#
if [ -f $LASTTIME ];then
	ECHO "前回実施時のバックアップが存在しています。"
	ECHO -n "バックアップから元に戻しますか？(Y/N) :"
	read ANS

	if [ ${ANS} = "Y" -o ${ANS} = "y" ]
	then
		cat ${LASTTIME} | while read LINE
		do
			ECHO "処理 ${LINE}"
			cp -p `cat ${LASTTIME_BACKUP}`/${LINE} $LINE
		done
		ECHO "バックアップから戻しました"
		FINISH
	fi
fi
rm -fr $LASTTIME
rm -fr $LASTTIME_BACKUP
rm -fr $BACKUP_DIR

####################################################
#
# 対象プロジェクトを尋ねる
#
ECHO
ECHO " プロジェクトのフルパスを入力して下さい"
ECHO -n ":"
read PROJ_PATH
if [ -z ${PROJ_PATH} ]
then
	ECHO "不正なパスです"
	FINISH
fi

if [ ! -d ${PROJ_PATH} ]
then
	ECHO "ディレクトリが見つかりませんでした"
	FINISH
fi

####################################################
#
# .mファイルを探索する
#
ECHO -n "〜.mファイルを探索しています..."
find $PROJ_PATH -name "*.m" > $M_FILE_LIST

M_FILE_COUNT=$((`cat ${M_FILE_LIST} | wc -l`))
if [ ${M_FILE_COUNT} -eq 0 ]
then
	ECHO "〜.mファイルが見つかりませんでした"
	FINISH
fi
ECHO "${M_FILE_COUNT}件みつかりました"

####################################################
#
# ログの形式を選ぶ
#

#埋めこむログのフォーマット


ECHO
ECHO
ECHO "埋め込むログの形式を選択してください"
ECHO 
ECHO " [NSLogをベタ書きする]"
ECHO "    ┃"
ECHO "    ┣━━━(1) メソット開始時に、メソッド名、行番号を出力"
ECHO "    ┃"
ECHO "    ┗━━━(2) メソット開始時に、ファイル名、メソッド名、行番号を出力"
ECHO ""
ECHO " [NSLogをフラグで切替え]"
ECHO "    ┃"
ECHO "    ┣━━━(3) メソット開始時に、メソッド名、行番号を出力"
ECHO "    ┃"
ECHO "    ┗━━━(4) メソット開始時に、ファイル名、メソッド名、行番号を出力"
ECHO ""
ECHO -n "(1〜4):"

read LOG_STYLE
if [ -z ${LOG_STYLE} ]
then
	ECHO "不正な入力です"
	FINISH
fi

ECHO
ECHO
REPLACE=""
case ${LOG_STYLE} in
  1 ) 
	ECHO "全ファイル、全メソッドの先頭に"
	ECHO "  NSLog(@\"${PREFIX}: %s:%d\", __PRETTY_FUNCTION__,__LINE__);"
	ECHO "を埋め込みます"
	ECHO ""
	ECHO "出力例"
	ECHO "  ${PREFIX}: -[sampleClass sampleMethod:]:999"
	ECHO ""
	REPLACE="NSLog(@\"${PREFIX}: %s:%d\", __PRETTY_FUNCTION__,__LINE__);"
	;;
  2 ) 
	ECHO "全ファイル、全メソッドの先頭に"
	ECHO "  NSLog(@\"${PREFIX}: %@:%d:%s\",[[NSString stringWithUTF8String:__FILE__] lastPathComponent],__LINE__,__PRETTY_FUNCTION__);"
	ECHO "を埋め込みます"
	ECHO ""
	ECHO "出力例"
	ECHO "  ${PREFIX}: sampleFile.m:999:-[sampleClass sampleMethod:]"
	ECHO ""
	REPLACE="NSLog(@\"${PREFIX}: %\@:%d:%s\",[[NSString stringWithUTF8String:__FILE__] lastPathComponent],__LINE__,__PRETTY_FUNCTION__);"
	;;
  3 ) 
	ECHO "全ファイル、全メソッドの先頭に"
	ECHO "  #ifdef ${FLAG}"
	ECHO "      NSLog(@\"${PREFIX}: %s:%d\", __PRETTY_FUNCTION__,__LINE__);"
	ECHO "  #endif"
	ECHO "を埋め込みます"
	ECHO ""
	ECHO "出力例"
	ECHO "  ${PREFIX}: -[sampleClass sampleMethod:]:999"
	ECHO ""
	REPLACE="#ifdef ${FLAG}\n    NSLog(@\"${PREFIX}: %s:%d\", __PRETTY_FUNCTION__,__LINE__);\n#endif"
	;;
  4 ) 
	ECHO "全ファイル、全メソッドの先頭に"
	ECHO "  #ifdef ${FLAG}"
	ECHO "       NSLog(@\"${PREFIX}: %@:%d:%s\",[[NSString stringWithUTF8String:__FILE__] lastPathComponent],__LINE__,__PRETTY_FUNCTION__);"
	ECHO "  #endif"
	ECHO "を埋め込みます"
	ECHO ""
	ECHO "出力例"
	ECHO "  ${PREFIX}: sampleFile.m:999:-[sampleClass sampleMethod:]"
	ECHO ""
	REPLACE="#ifdef ${FLAG}\n    NSLog(@\"${PREFIX}: %\@:%d:%s\",[[NSString stringWithUTF8String:__FILE__] lastPathComponent],__LINE__,__PRETTY_FUNCTION__);\n#endif"
	;;
  * ) 
	ECHO "不正な入力です" 
    FINISH
    ;;
esac

####################################################
#
# 本当に変換していいのか確認する
#
ECHO -n "ログメソッドを埋め込んでよろしいですか? (Y/N) :"
read ANS

if [ ! ${ANS} = "Y" -a ! ${ANS} = "y" ]
then
	FINISH
fi

####################################################
#
# バックアップを取得
#
ECHO
ECHO "バックアップを作成しています"
rm -fr ${BACKUP_DIR}
cat ${M_FILE_LIST} | while read LINE
do
	mkdir -p ${BACKUP_DIR}/`dirname $LINE`
	cp -p $LINE ${BACKUP_DIR}/$LINE
done
ECHO "${BACKUP_DIR}にバックアップを保存しました"


####################################################
#
# 変換実施
#
ECHO
ECHO "メソッドを走査しログメソッドを挿入します"

cat ${M_FILE_LIST} | while read LINE
do
	ECHO " 処理 ${LINE}"
	perl -0pe "s/^[-\+]\s*\(.+?\)[_a-zA-Z][_a-zA-Z0-9]*[a-z]+[_a-zA-Z0-9]*[ \t]*[\S\s]*?\{/$&\n${REPLACE}\n/mg" ${LINE} > /tmp/work
	cat /tmp/work > ${LINE}
done

ECHO "正常終了 `date`"
ECHO "Xcodeでビルドを実施してください。"
ECHO "ビルドエラーになった場合はバックアップから元に戻すことも可能です"
ECHO "(再度、本シェルを実施してください)"
cat  $M_FILE_LIST > $LASTTIME
echo $BACKUP_DIR  > $LASTTIME_BACKUP
FINISH
