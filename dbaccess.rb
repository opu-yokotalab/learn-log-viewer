require 'postgres'

class DBAccess
  def initialize
    host = 'localhost'
    port = 5432
    dbname = 'adel_v2'
    user = 'learn'
    pass = 'learn'
    
    begin
      @conn = PGconn.connect(host,port,'','',dbname,user,pass)
    rescue
      exit
    end
  end
  
  def getByModuleName(module_id)
    if module_id != -1
      res = @conn.exec("select module_name from ent_modules where id = #{module_id}")
      return res.result[0][0]
    end
  end

  def getByModuleTimes(u_id , s_id , time_from , time_to)
    res = @conn.exec("select ent_module_id , count(ent_module_id) from module_logs where user_id = '#{u_id}' and ent_seq_id='#{s_id}' and created_on >= '#{time_from}' and created_on <= '#{time_to}' group by ent_module_id order by ent_module_id")
    return res.result
  end

  def getByModuleTimesAll(u_id , time_from , time_to)
    res = @conn.exec("select ent_module_id , count(ent_module_id) from module_logs where user_id = '#{u_id}' and created_on >= '#{time_from}' and created_on <= '#{time_to}' group by ent_module_id order by ent_module_id")
    return res.result
  end

  def getByTestMaxPoint(test_id)
    res = @conn.exec("select max_sum_point from ent_tests where id = '#{test_id}'")
    return res.result[0]
  end

  def getByTestPointAndTime(user_id , test_id , time_from , time_to)
    res = @conn.exec("select created_on , sum_point from test_logs where user_id = '#{user_id}' and ent_test_id = '#{test_id}' and created_on >= '#{time_from}' and created_on <= '#{time_to}' order by created_on")
    return res.result
  end

  def getByModuleTimeZoneAll(user_id , time_from , time_to)
    res = @conn.exec("select module_logs.ent_seq_id , module_logs.ent_module_id , module_logs.created_on from module_logs,ent_modules where module_logs.user_id = '#{user_id}' and module_logs.ent_module_id = ent_modules.id and module_logs.created_on >= '#{time_from}' and module_logs.created_on <= '#{time_to}' order by created_on")
    res_array = Array.new
    i = 0
    while(i < res.result.length - 1)
      r = res.result[i]
      if r[1].to_i != -1
        res_array.push([ r[1],r[2], res.result[i+1][2] ])
      end
      i += 1
    end
    return res_array
  end

  def getByModuleTimeZone(user_id,seq_id,time_from , time_to)
    res = @conn.exec("select module_logs.ent_seq_id , module_logs.ent_module_id , module_logs.created_on from module_logs,ent_modules where module_logs.user_id = '#{user_id}' and module_logs.ent_seq_id = '#{seq_id}' and module_logs.ent_module_id = ent_modules.id and module_logs.created_on >= '#{time_from}' and module_logs.created_on <= '#{time_to}' order by created_on")
    res_array = Array.new
    i = 0
    while(i < res.result.length - 1)
      r = res.result[i]
      if r[1].to_i != -1
        res_array.push([ r[1],r[2], res.result[i+1][2] ])
      end
      i += 1
    end
    return res_array
  end

  def dbClose
    # DB Close
    @conn.close
  end
end
