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
  
  def getByUserID(login)
    res = @conn.exec("select id from users where login = '#{login}'")
    return res.result[0][0]
  end

  def getByUserList
    res = @conn.exec("select login from users order by id")
    return res.result
  end

  def getByModuleName(module_id)
    if module_id != -1
      res = @conn.exec("select module_name from ent_modules where id = #{module_id}")
      return res.result[0]
    end
  end

  def getByModuleTimes(u_id , s_id)
    res = @conn.exec("select ent_module_id , count(ent_module_id) from module_logs where user_id = '#{u_id}' and ent_seq_id='#{s_id}' group by ent_module_id order by ent_module_id")
    return res.result
  end

  def getByModuleTimesAll(u_id)
    res = @conn.exec("select ent_module_id , count(ent_module_id) from module_logs where user_id = '#{u_id}' group by ent_module_id order by ent_module_id")
    return res.result
  end

  def getByTestMaxPoint(test_name)
    res = @conn.exec("select max_sum_point from ent_tests where test_name = '#{test_name}'")
    return res.result[0]
  end

  def getByTestID(test_name)
    res = @conn.exec("select id from ent_tests where test_name = '#{test_name}'")
    return res.result[0]
  end

  def getByTestPointAndTime(user_id , test_id)
    res = @conn.exec("select created_on , sum_point from test_logs where user_id = '#{user_id}' and ent_test_id = '#{test_id}' order by created_on")
    return res.result
  end

  def getByModuleTimeZoneAll(user_id)
    res = @conn.exec("select module_logs.ent_seq_id , module_logs.ent_module_id , module_logs.created_on from module_logs,ent_modules where module_logs.user_id = '#{user_id}' and module_logs.ent_module_id = ent_modules.id order by created_on")
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

  def getByModuleTimeZone(user_id,seq_id)
    res = @conn.exec("select module_logs.ent_seq_id , module_logs.ent_module_id , module_logs.created_on from module_logs,ent_modules where module_logs.user_id = '#{user_id}' and module_logs.ent_seq_id = '#{seq_id}' and module_logs.ent_module_id = ent_modules.id order by created_on")
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
