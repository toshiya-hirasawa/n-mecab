#MeCab+Unidicの組み合わせでN-gramを作成
#Unidicの出力は全てデフォルトのまま
@include "functions.awk"	#絶対パス、もしくは処理ファイルからの相対パスを指定する。
BEGINFILE{
	if(ERRNO){
		print FILENAME "が見つかりません。"
		print "このまま続けますか？"
		print "続ける:1 確認する:2"
		getline answer1 <"-"
		while(answer1!=1&&answer1!=2){
			print "正しい数字を選択してください"
			getline answer1 <"-"
		}
		if(answer1==2){
			exit
		}
		nextfile
	}
}

BEGIN{
	#ファイルの処理順をソートする
	for(item=1;item<=ARGC-1;item++){#ファイル名を入力順にファイル名配列に格納
		file_name_array[item] = ARGV[item]
	}
	PROCINFO["sorted_in"] = "@val_str_asc";
	asort(file_name_array)#ソート
	for(item=1;item<=ARGC-1;item++){#書き戻し
		ARGV[item] = file_name_array[item]
	}
	FS="\t"

	print "結果を保存しますか？"
	print "追記する:1 上書き保存する:2 保存しない:3"
	getline answer2 <"-"
	while(answer2!=""&&answer2!=1&&answer2!=2&&answer2!=3){#例外処理
		print "正しい数字を選択してください"
		getline answer2 <"-"
	}
	if(answer2==""){
		answer2=3
	}else if(answer2==1||answer2==2){
		print "どのファイルに保存しますか？"
		getline output_file_name <"-"#ファイル名指定
		while(output_file_name==""){#空白ならもう一度
			getline output_file_name <"-"
		}
	}


	print "グラムの単位"
	print "書字形:1 語彙素:2"
	getline unit <"-"
	while(unit!=""&&unit!=1&&unit!=2){#例外処理
		print "正しい数字を選択してください"
		getline unit <"-"
	}
	if(unit==""){
		unit = 1
	}
	unit ++

	OFS = ","	#項目の区切
	pOFS = ","

	gram_sep = "/"	#単語の区切
	pgram_sep = "/"

	part_sep = "/"	#品詞の区切記号
	ppart_sep = "/"

	print "原文:1 読み:2"
	getline mode <"-"
	while(mode!=""&&mode!=1&&mode!=2){#適切な値が入力されているかどうか
		print "正しい数字を選択してください"
		getline mode <"-"
	}
	if(mode==""){#何も入力されなかった場合は原文モードを設定
		mode = 1
	}

	set_span()
	if(min==""){
		if(max==""){#いずれの値にも入力されなかった場合は1~10gramを設定
			min = 1
			max = 10
		}else{
			min = max
		}
	}else if(max==""){#一方の値のみ入力された場合は同値を設定
		max = min
	}

	while(min > max){#適切な値が入力されているかどうか
		print "最小値は最大値より小さいものを設定してください"
		set_span()
	}

	pmin = min
	pmax = max
	min = min * 2 + 1
	max = max * 2 + 1

	#設定値の表示
	if(answer1==1){
		print "追記"
	}else if(answer2==2){
		print "上書き"
	}else if(answer2==3){
		print "保存しない"
	}

	if(unit==1){
		print "文字"
	}else if(unit==2){
		print "書字形"
	}else{
		print "語彙素"
	}

	if(mode==1){
		print "原文"
	}else{
		print "読み"
	}

	print "項目の区切記号:" pOFS
	print "グラムの区切記号:" pgram_sep
	print "品詞の区切記号:" ppart_sep

	if(min<max){
		print "スパン " pmin " から " pmax " まで"
	}else{
		print "スパン " pmin 
	}

	print#データ本体との改行
}

{
	command = "echo " $0 "|mecab"
	while(command | getline){#一行ずつMeCabに渡し、コマンド実行結果を取得
		if($0 !~/EOS/){
			gram_unit()
			set_mode()
			input()
			number_of_words ++
		}
	}
	close(command)
	#解析対象のテキストファイルは一文ごとに改行したもの
	#テキストファイルから一行ずつ読み込み
	#MeCabに放り込む
	#MeCabの解析結果が続く限り、一行ずつ読み込み
	#EOSが来たら、何もしない
		

	if(answer2==2||answer2==3){
		for(n=1;n<=1;n+=2){
			if(unit==1){
				for(position=1;position<=(length(sentence)-n+1);position++){
				#文字列の先頭から、最後のgramの先頭の文字まで繰り返す
					gram_tail = position + n - 1
					#gramの最後尾が先頭から何文字目か

					if(w_array2[gram_tail] != ""){
					#gramの最後尾と対応する形態素情報が空要素じゃない
					#つまりgramの最後尾が形態素の最後尾と一致する場合
					#8gramで「イトは精神分析家」
						if(n<=w_array1[gram_tail]){
						#gram数が形態素の文字数より短い場合
						#gramは一つの形態素から構成されている
						#3gramで「フロイト」
							#gramの単純出力と対応する形態素情報の出力
							arr_item = n SUBSEP substr(sentence,position,n) OFS w_array2[gram_tail]
							#arr_item = substr(sentence,position,n) OFS w_array2[gram_tail]
							s_array[arr_item,FILENAME]++
						}else{
						#gram数が形態素の文字数より長い場合
						#gramは複数の形態素から構成されている
						#5gramで「フロイトは」
							joint()
							sub(part_sep"$","",part)
							sub(gram_sep"$","",keyword)
							#数珠つなぎの最後の区切り記号を削る
							arr_item = n SUBSEP keyword OFS part
							#arr_item = keyword OFS part
							s_array[arr_item,FILENAME]++
							initialize()
						}
					}else{
						#6gramで「イトは精神分」
						joint()
						while(w_array2[gram_tail]==""){
						#gramの最後尾から、形態素の最後尾、つまり区切り位置までインクリメント
							gram_tail++
						}
						part = part w_array2[gram_tail]
						keyword = keyword substr(sentence,pre_item,n-key_length)
						#含まれる最後の形態素（gramには途中まで）の追加
						#処理済みの文字数を控除
						arr_item = n SUBSEP keyword OFS part
						#arr_item = keyword OFS part
						s_array[arr_item,FILENAME]++

						initialize()
					}
				}
			}else if(unit==2||unit==3){#単語、形態素単位の場合
				num = 0
				#一文あたりの語数の初期化
				for(item=1;item<=w_tail;item++){
					#文頭から文末まで
	
					if(w_array2[item]!=""){
						num++
						#語数は先に加算
						part_array[num] =w_array2[item]
						morpheme[num] = substr(sentence,item-w_array1[item]+1,w_array1[item])
						#品詞情報用の配列、単語・形態素用の配列にそれぞれ格納
					}
				}
				for(s_pos=1;s_pos<=num-n+1;s_pos++){
					#グラムの始点
					for(pos=s_pos;pos<=s_pos+n-1;pos++){
						keyword = keyword morpheme[pos] gram_sep
						part = part part_array[pos] part_sep
						#一語ずつ数珠つなぎ
					}
					sub(part_sep"$","",part)
					sub(gram_sep"$","",keyword)
					arr_item = n SUBSEP keyword OFS part
					s_array[arr_item,FILENAME]++
					initialize()
				}
				delete part_array
				delete morpheme
			}
		}
	}

	for(n=min;n<=max;n+=2){
		if(unit==1){
			for(position=1;position<=(length(sentence)-n+1);position++){
			#文字列の先頭から、最後のgramの先頭の文字まで繰り返す
				gram_tail = position + n - 1
				#gramの最後尾が先頭から何文字目か
				if(w_array2[gram_tail] != ""){
				#gramの最後尾と対応する形態素情報が空要素じゃない
				#つまりgramの最後尾が形態素の最後尾と一致する場合
				#8gramで「イトは精神分析家」
					if(n<=w_array1[gram_tail]){
					#gram数が形態素の文字数より短い場合
					#gramは一つの形態素から構成されている
					#3gramで「フロイト」
						#print substr(sentence,position,n),w_array2[gram_tail]
						#gramの単純出力と対応する形態素情報の出力
						#グラム数、グラム本体、品詞情報
						arr_item = n SUBSEP substr(sentence,position,n) OFS w_array2[gram_tail]
						s_array[arr_item,FILENAME]++
					}else{
					#gram数が形態素の文字数より長い場合
					#gramは複数の形態素から構成されている
					#5gramで「フロイトは」
						joint()
						sub(part_sep"$","",part)
						sub(gram_sep"$","",keyword)
						#数珠つなぎの最後の区切り記号を削る
						arr_item = n SUBSEP keyword OFS part
						s_array[arr_item,FILENAME]++
						initialize()
					}
				}else{
					#6gramで「イトは精神分」
					#「ト／は／」を先に追加、後から「析」を追加
					joint()
					while(w_array2[gram_tail]==""){
					#gramの最後尾から、形態素の最後尾、つまり区切り位置までインクリメント
						gram_tail++
					}
					part = part w_array2[gram_tail]
					keyword = keyword substr(sentence,pre_item,n-key_length)
					#含まれる最後の形態素（gramには途中まで）の追加
					#処理済みの文字数を控除
					arr_item = n SUBSEP keyword OFS part
					s_array[arr_item,FILENAME]++
					initialize()
				}
			}
		}else if(unit==2||unit==3){#単語、形態素単位の場合
			num = 0#一文あたりの語数の初期化
			for(item=1;item<=w_tail;item++){
				#文頭から文末まで

				if(w_array2[item]!=""){
					num++
					#語数は先に加算
					part_array[num] =w_array2[item]
					morpheme[num] = substr(sentence,item-w_array1[item]+1,w_array1[item])
					#item は現在の語末の位置
					#品詞情報用の配列、単語・形態素用の配列にそれぞれ格納
				}
			}
			for(s_pos=1;s_pos<=num-n+1;s_pos++){#グラム全体の移動
				#グラムの始点
				for(pos=s_pos;pos<=s_pos+n-1;pos++){#グラムの中の移動
					keyword = keyword morpheme[pos] gram_sep
					part = part part_array[pos] part_sep
					#一語ずつ数珠つなぎ
				}
				sub(part_sep"$","",part)
				sub(gram_sep"$","",keyword)
				arr_item = n SUBSEP keyword OFS part
				s_array[arr_item,FILENAME]++
				initialize()
			}
			delete part_array
			delete morpheme
		}
	}
	w_tail = ""
	sentence = ""
	delete w_array1
	delete w_array2
	#配列の初期化
}
END{
	if(answer1==2){#ファイルが存在しない場合の終了命令
		exit
	}

	for(name=1;name<=ARGC-1;name++){#ファイル名をつないでヘッダをつくる
		files = files ARGV[name] OFS
	}
	sub(OFS"$","",files)
	if(answer2==1){#追記だったらヘッダを出力しない
	}else if(answer2==2){#新規or上書きだったらヘッダを出力
		print number_of_words > output_file_name
		print files > output_file_name
	}else if(answer2==3){#標準出力なら語数とヘッダを出力
		print number_of_words
		print files
	}

	num_gram = 1
	PROCINFO["sorted_in"]="@ind_str_asc";
	for(item in s_array){
		material =  item SUBSEP s_array[item]
		split(material,item_array,SUBSEP)#s_array はソート済みなので、last_array もソート済み
		last_array[num_gram][1] = item_array[1]	#Nの値
		last_array[num_gram][2] = item_array[2]	#グラム、OFS、品詞情報
		last_array[num_gram][3] = item_array[3]	#ファイル名
		last_array[num_gram][4] = item_array[4]	#出現頻度
		num_gram ++
	}
	num_gram = num_gram - 1
	for(count=1;count<=num_gram;count++){
		val1 = last_array[count][2]	#グラム、OFS、品詞情報
		val2 = last_array[count][3]	#ファイル名
		val3 = last_array[count][4]	#出現頻度
		val4 = last_array[count][1]	#Nの値

		if(val1==pre_val1){
			chain()
		}else{
			file_output()
			f_name = 1
			output = val4 OFS val1
			chain()
		}
	}
	file_output()
}
