#!/usr/bin/ruby
require 'cgi'
require 'time'
require 'dbaccess.rb'

def chartHeight(xy_array)
  # グラフの縦のサイズを求める(モジュールログ限定)
  if xy_array.length <= 3
    return 300
  elsif xy_array.length <= 5
    return 400
  elsif xy_array.length <= 7
    return 500
  else
    return 600
  end
end

def xy_max(xy_array)
  # xy_array 最大値を求める
  max_value = 0
  xy_array.each do |v|
    if max_value < v[1]
      max_value = v[1]
    end
  end
  return max_value
end

def arrayKeys(array)
  keys = Array.new
  array.each do |v|
    keys.push(v[0])
  end
  return keys
end

def arrayValues(array)
  values = Array.new
  array.each do |v|
    values.push(v[1])
  end
  return values
end

def textEncode(array,max_value)
  encode_array = Array.new
  array.each do |v|
    # y軸の目盛値の整数，小数の切り替えのための前処理
    if v[1].class == Float
      encode_array.push([v[0],v[1]/max_value.to_f*100])
    else
      encode_array.push([v[0],(v[1]/max_value.to_f*100).to_i])
    end
  end
  return encode_array
end

def setParams(chs,cht,chxt,array,max_value,y_split)
  chParams = Hash.new
  chParams.store("chs",chs)
  chParams.store("cht",cht)
  chParams.store("chxt",chxt)
  
  # make chm
  if cht =~ /lc/
    chm = ""
    (array.length - 1).times do |i|
      chm += "o,FFCC33,0,#{i}.0,10.0|"
    end
    chm += "o,FFCC33,0,#{array.length - 1}.0,10.0"
    chParams.store("chm",chm)
  end
  # make chd
  chParams.store("chd","t:#{arrayValues(array).join(',')}")
  # make chxl
  if chxt == "x,y"
    chxl = "0:|#{arrayKeys(array).join('|')}"
  elsif chxt == "y,x"
    chxl = "0:|#{arrayKeys(array).reverse.join('|')}"
  end
  chxl += "|1:|0"
  n = 1

  # y軸の目盛値の整数か小数かの判定
  float_flag = false
  array.each do |i|
    if i[1].class == Float
      float_flag = true
      break
    end
  end
  # y軸の目盛描画
  y_split.times do
    if float_flag
      chxl += "|#{sprintf("%.2f",max_value.to_f/y_split*n)}"
    else
      chxl += "|#{(max_value.to_f/y_split*n).to_i}"
    end
    n += 1
  end
  chParams.store("chxl",chxl)
  return chParams
end

# GoogleChart imgタグ生成関数
# 引数
# chs:画像サイズ,cht:グラフタイプ,chxt:x軸とy軸,array:グラフの値のハッシュ
# max_value:プロット値の最大値, y_split:y軸の目盛の分割数
def makeChart(chs,cht,chxt,array,max_value,y_split)
  encode_array = textEncode(array,max_value)
  chParams = setParams(chs,cht,chxt,encode_array,max_value,y_split)
  
  chartURL = "http://chart.apis.google.com/chart?"
  chartURL += "chs=#{chParams["chs"]}"
  chartURL += "&chd=#{chParams["chd"]}"
  chartURL += "&cht=#{chParams["cht"]}"
  if chParams.key?("chm")
    chartURL += "&chm=#{chParams["chm"]}"
  end
  chartURL += "&chxt=#{chParams["chxt"]}"
  chartURL += "&chxl=#{chParams["chxl"]}"
  
  imgTag = "<img src='#{chartURL}' alt=\"Sample Chart\" />"
  return imgTag
end

# Output function
def view(v1,v2)
  print "Content-type: text/html\n\n"
  p v1
  print "<br />"
  print v2
end

cgi = CGI.new

# Get Message Input
query_str = Hash.new
query_str.store("login",cgi["login"])
query_str.store("log_type",cgi["log_type"])
query_str.store("view_type",cgi["view_type"])
query_str.store("seq_id",cgi["seq_id"])
query_str.store("test_id",cgi["test_id"])

query_str.store("year_from",cgi["year_from"])
query_str.store("month_from",cgi["month_from"])
query_str.store("day_from",cgi["day_from"])
query_str.store("hour_from",cgi["hour_from"])

query_str.store("year_to",cgi["year_to"])
query_str.store("month_to",cgi["month_to"])
query_str.store("day_to",cgi["day_to"])
query_str.store("hour_to",cgi["hour_to"])

# Error
if query_str["login"] =~ /none/
  view("Please select Login ID!!","Error!")
  exit
end

# make DB instance
logDB = DBAccess.new

# make Time object
if query_str["hour_from"] =~ /none/
  query_str["hour_from"] = 0
end
if query_str["hour_to"] =~ /none/
  query_str["hour_to"] = 0
end

time_from = "#{query_str["year_from"]}/#{query_str["month_from"]}/#{query_str["day_from"]} #{query_str["hour_from"]}:00"
time_to = "#{query_str["year_to"]}/#{query_str["month_to"]}/#{query_str["day_to"]} #{query_str["hour_to"]}:00"

# make Time format
time_from = Time.parse(time_from).strftime("%Y-%m-%d %H:%M")
time_to = Time.parse(time_to).strftime("%Y-%m-%d %H:%M")

# Module or Test
# Print to Module Log
if query_str["log_type"] =~ /module/  
  if query_str["seq_id"] =~ /none/
    view("Please select SEQ!!","Error!")
    exit
  # モジュール閲覧回数グラフの描画
  elsif query_str["view_type"] =~ /number/
    
    # 全単元か否か
    if query_str["seq_id"] =~ /all/
      mod_times = logDB.getByModuleTimesAll(query_str["login"],time_from,time_to)
    else
      mod_times = logDB.getByModuleTimes(query_str["login"] , query_str["seq_id"] ,time_from , time_to)
    end
    
    xy_array = Array.new
    mod_times.each do |v|
      mod_name = logDB.getByModuleName(v[0].to_i)
      if mod_name
        xy_array.push([mod_name,v[1].to_i])
      end
    end
    
    max_value = xy_max(xy_array)
    height = chartHeight(xy_array)

    out_img_tag = makeChart("500x#{height}","bhg","y,x",xy_array,max_value,max_value)    
    
  # モジュール閲覧時間グラフの描画
  elsif query_str["view_type"] =~ /time/

    # 全単元か否か
    if query_str["seq_id"] =~ /all/
      mod_timezone = logDB.getByModuleTimeZoneAll(query_str["login"] , time_from , time_to)
    else
      mod_timezone = logDB.getByModuleTimeZone(query_str["login"] , query_str["seq_id"] , time_from , time_to)
    end
    
    mod_hash = Hash.new
    mod_timezone.each do |v|
      t1 = Time.parse(v[1])
      t2 = Time.parse(v[2])

      # 時間の差分を求めハッシュに追加
      if mod_hash.key?(v[0])
        mod_hash[v[0]] = mod_hash[v[0]] + (t2 - t1)
      else
        mod_hash.store(v[0],t2-t1)
      end
    end
    xy_array = mod_hash.to_a.sort
    y_split = 10
    
    xy_array.each do |v|
      v[0] = logDB.getByModuleName(v[0].to_i)
      v[1] = v[1].to_f/60
      # グラフy軸の上限値　300分
      if 300 < v[1]
        v[1] = 300
      end
    end

    max_value = xy_max(xy_array)
    height = chartHeight(xy_array)
    out_img_tag = makeChart("500x#{height}","bhg","y,x",xy_array,max_value,5)
  end
# Print to Test Log
elsif query_str["log_type"] =~ /test/
  if query_str["test_id"] =~ /none/
    view("Please select Test!!","Error!")
    exit
  else
    # get test Max Point
    max_point = logDB.getByTestMaxPoint(query_str["test_id"])[0]
    # get test point , time from test_logs
    point_and_time = logDB.getByTestPointAndTime(query_str["login"] , query_str["test_id"] , time_from , time_to)
    
    xy_array = Array.new
    i = 0
    point_and_time.each do |pt|
      x_time = Time.parse(pt[0])
      xy_array.push([x_time.strftime("%m/%d-%H:%M"),pt[1].to_i])
      i+=1
    end
    
    out_img_tag = makeChart("700x300","lc","x,y",xy_array,max_point,10)
  end
end

# DB Connect Close
logDB.dbClose
  
# View
view(xy_array,out_img_tag)

