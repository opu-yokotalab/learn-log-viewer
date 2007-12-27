#!/usr/bin/ruby
require 'cgi'
require 'time'
require 'dbaccess.rb'

def xy_max(xy_array)
  # xy_array 最大値を求める
  max_value = 0
  xy_array.each do |v|
    if max_value < v[1].to_i
      max_value = v[1].to_i
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
    encode_array.push([v[0],v[1].to_i/max_value.to_f*100])
  end
  return encode_array
end

def setParams(chs,cht,chxt,array,max_value,y_split)
  chParams = Hash.new
  chParams.store("chs",chs)
  chParams.store("cht",cht)
  chParams.store("chxt",chxt)
  
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
  y_split.times do
    chxl += "|#{(max_value.to_f/y_split*n).to_i}"
    n += 1
  end
  chParams.store("chxl",chxl)
  return chParams
end

# GoogleChart imgタグ生成関数
# 引数：chs 画像サイズ,cht グラフタイプ,chxt x軸とy軸,array グラフの値のハッシュ
# max_value プロット値の最大値,y軸の目盛の分割数
def makeChart(chs,cht,chxt,array,max_value,y_split)
  encode_array = textEncode(array,max_value)
  chParams = setParams(chs,cht,chxt,encode_array,max_value,y_split)
  
  chartURL = "http://chart.apis.google.com/chart?"
  chartURL += "chs=#{chParams["chs"]}"
  chartURL += "&chd=#{chParams["chd"]}"
  chartURL += "&cht=#{chParams["cht"]}"
  chartURL += "&chxt=#{chParams["chxt"]}"
  chartURL += "&chxl=#{chParams["chxl"]}"
  
  imgTag = "<img src='#{chartURL}' alt=\"Sample Chart\" />"
  return imgTag
end

# Output function
def view(v1,v2)
  print "Content-type: text/html\n\n"
  p v1
  print "<br /><br />"
  print v2
end

cgi = CGI.new

# Get Message Input
query_str = Hash.new
query_str.store("login",cgi["login"])
query_str.store("log_type",cgi["log_type"])
query_str.store("view_type",cgi["view_type"])
query_str.store("seq_id",cgi["seq_id"])
query_str.store("test_name",cgi["test_name"])

query_str.store("year_from",cgi["year_from"])
query_str.store("month_from",cgi["month_from"])
query_str.store("day_from",cgi["day_from"])
query_str.store("hour_from",cgi["hour_from"])

query_str.store("year_to",cgi["year_to"])
query_str.store("month_to",cgi["month_to"])
query_str.store("day_to",cgi["day_to"])
query_str.store("hour_to",cgi["hour_to"])

# make DB instance
logDB = DBAccess.new

# get user id
user_id = logDB.getByUserID(query_str["login"])

# Module or Test
# Print to Module Log
if query_str["log_type"] =~ /module/
  if query_str["view_type"] =~ /number/
    
    if query_str["seq_id"] =~ /all/
      mod_times = logDB.getByModuleTimesAll(user_id)
    else
      mod_times = logDB.getByModuleTimes(user_id , query_str["seq_id"])
    end
    
    xy_array = Array.new
    mod_times.each do |v|
      mod_name = logDB.getByModuleName(v[0].to_i)
      if mod_name
        xy_array.push([mod_name,v[1]])
      end
    end
    
    max_value = xy_max(xy_array)

    out_img_tag = makeChart("500x600","bhg","y,x",xy_array,max_value,max_value)    
    
  elsif query_str["view_type"] =~ /time/

    if query_str["seq_id"] =~ /all/
      mod_timezone = logDB.getByModuleTimeZoneAll(user_id)
    else
      mod_timezone = logDB.getByModuleTimeZone(user_id , query_str["seq_id"])
    end
    
    mod_hash = Hash.new
    mod_timezone.each do |v|
      t1 = Time.parse(v[1])
      t2 = Time.parse(v[2])

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
      if 300 < v[1]
        v[1] = 300
      end
    end

    max_value = xy_max(xy_array)
    out_img_tag = makeChart("500x600","bhg","y,x",xy_array,max_value,5)
  end
# Print to Test Log
elsif query_str["log_type"] =~ /test/
  # get test Max Point
  max_point = logDB.getByTestMaxPoint(query_str["test_name"])[0]
  # get test point , time from test_logs
  point_and_time = logDB.getByTestPointAndTime(user_id , logDB.getByTestID(query_str["test_name"]))

  xy_array = Array.new
  i = 0
  point_and_time.each do |pt|
    x_time = Time.parse(pt[0])
    xy_array.push([x_time.strftime("%m/%d-%H:%M"),pt[1]])
    i+=1
  end
  
  out_img_tag = makeChart("700x300","lc","x,y",xy_array,max_point,10)
end

# DB Connect Close
logDB.dbClose
  

if true
view(query_str,"dummy")
else
# View
view(xy_array,out_img_tag)
end
