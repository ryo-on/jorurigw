# -*- encoding: utf-8 -*-
class Gwqa::Script::Annual

  def self.renew(start_date = nil)
    if start_date.blank?
      return false
    else
      @start_date = start_date
    end
    p "質問管理(Q&A)年次切替所属情報更新 開始:#{Time.now}."
    renew_adms
    renew_admingrps_json
    renew_roles
    renew_editors_json
    renew_readers_json
    renew_docs_section_code
    renew_dsp_admin_name
    p "質問管理(Q&A)年次切替所属情報更新 終了:#{Time.now}."
  end

  def self.renew_adms
    p "renew_adms 開始:#{Time.now}."
    sql  = 'SELECT group_id, group_code'
    sql += " FROM gwqa_adms"
    sql += " GROUP BY group_id, group_code"
    sql += " ORDER BY group_id, group_code"
    adms = Gwqa::Adm.find_by_sql(sql)
    for adm in adms
      item = Gwboard::RenewalGroup.new
      item.and :present_group_id, adm.group_id
      item.and :present_group_code, adm.group_code
      item.and :start_date, @start_date
      group = item.find(:first, :order=> 'present_group_id, present_group_code')
      next if group.blank?

      update_fields="group_id=#{group.incoming_group_id}, group_code='#{group.incoming_group_code}',group_name='#{group.incoming_group_name}'"
      sql_where = "group_id=#{adm.group_id} AND group_code='#{adm.group_code}'"
      Gwqa::Adm.update_all(update_fields, sql_where)
      p "#{adm.group_id}, #{adm.group_code}, #{update_fields}, #{Time.now}."
    end
    p "renew_adms 終了:#{Time.now}."
  end

  def self.renew_admingrps_json
    p "renew_admingrps_json 開始:#{Time.now}."

    title = Gwqa::Control.new
    titles = title.find(:all, :order=>'id')

    for title in titles
      groups = JsonParser.new.parse(title.admingrps_json)
      is_update = false
      groups.each do |group|
        renewal = Gwboard::RenewalGroup.new
        renewal.and :present_group_id, group[1]
        renewal.and :present_group_code, group[0]
        renewal.and :start_date, @start_date
        if item = renewal.find(:first)
          group[0] = item.incoming_group_code
          group[1] = item.incoming_group_id.to_s
          group[2] = item.incoming_group_name
          is_update = true
        end
      end
      if is_update
        groups.uniq!
        update_field = "admingrps_json='#{JsonBuilder.new.build(groups)}'"
        Gwqa::Control.update_all(update_field, "id=#{title.id}")
        p "#{title.id}, #{update_field}, #{Time.now}."
      end
    end
    p "renew_admingrps_json 終了:#{Time.now}."
  end

  def self.renew_roles
    p "renew_roles 開始:#{Time.now}."

    sql  = 'SELECT group_id, group_code'
    sql += " FROM gwqa_roles"
    sql += " GROUP BY group_id, group_code"
    sql += " ORDER BY group_id, group_code"
    roles = Gwqa::Role.find_by_sql(sql)
    for role in roles
      next if role.group_id.blank?
      next if role.group_id == 0

      item = Gwboard::RenewalGroup.new
      item.and :present_group_id, role.group_id
      item.and :present_group_code, role.group_code
      item.and :start_date, @start_date
      group = item.find(:first, :order=> 'present_group_id, present_group_code')
      next if group.blank?

      update_fields="group_id=#{group.incoming_group_id}, group_code='#{group.incoming_group_code}',group_name='#{group.incoming_group_name}'"
      sql_where = "group_id=#{role.group_id} AND group_code='#{role.group_code}'"
      Gwqa::Role.update_all(update_fields, sql_where)
      p "#{role.group_id}, #{role.group_code}, #{update_fields}, #{Time.now}."
    end
    p "renew_roles 終了:#{Time.now}."
  end

  def self.renew_editors_json
    p "renew_editors_json 開始:#{Time.now}."

    title = Gwqa::Control.new
    titles = title.find(:all, :order=>'id')

    for title in titles
      groups = JsonParser.new.parse(title.editors_json)
      is_update = false
      groups.each_with_index do |group,idx|
        renewal = Gwboard::RenewalGroup.new
        renewal.and :present_group_id, group[1]
        renewal.and :present_group_code, group[0]
        renewal.and :start_date, @start_date
        if item = renewal.find(:first)
          group[0] = item.incoming_group_code
          group[1] = item.incoming_group_id.to_s
          group[2] = item.incoming_group_name
          is_update = true
        end
      end
      if is_update
        groups.uniq!
        update_field = "editors_json='#{JsonBuilder.new.build(groups)}'"
        Gwqa::Control.update_all(update_field, "id=#{title.id}")
        p "#{title.id}, #{update_field}, #{Time.now}."
      end
    end
    p "renew_editors_json 終了:#{Time.now}."
  end

  def self.renew_readers_json
    p "renew_readers_json 開始:#{Time.now}."

    title = Gwqa::Control.new
    titles = title.find(:all, :order=>'id')

    for title in titles
      groups = JsonParser.new.parse(title.readers_json)
      is_update = false
      groups.each do |group|
        renewal = Gwboard::RenewalGroup.new
        renewal.and :present_group_id, group[1]
        renewal.and :present_group_code, group[0]
        if item = renewal.find(:first)
          group[0] = item.incoming_group_code
          group[1] = item.incoming_group_id.to_s
          group[2] = item.incoming_group_name
          is_update = true
        end
      end
      if is_update
        groups.uniq!
        update_field = "readers_json='#{JsonBuilder.new.build(groups)}'"
        Gwqa::Control.update_all(update_field, "id=#{title.id}")
        p "#{title.id}, #{update_field}, #{Time.now}."
      end
    end
    p "renew_readers_json 終了:#{Time.now}."
  end

  def self.renew_docs_section_code
    p "renew_docs_section_code 開始:#{Time.now}."

    items = Gwqa::Control.find(:all, :order=>'id')
    for @title in items
      begin
        doc_item = db_alias(Gwqa::Doc)
        sql  = 'SELECT section_code FROM gwqa_docs GROUP BY section_code ORDER BY section_code'
        docs = doc_item.find_by_sql(sql)
        for doc in docs
          next if doc.section_code.blank?

          group = Gwboard::RenewalGroup.find_by_present_group_code(doc.section_code)
          next if group.blank?

          update_fields = "section_code='#{group.incoming_group_code}', section_name='#{group.incoming_group_code}#{group.incoming_group_name}'"
          doc_item.update_all(update_fields, "section_code='#{doc.section_code}'")
          p "#{@title.dbname}, #{doc.section_code}, #{update_fields}, #{Time.now}."
        end
      rescue => ex
        p "ERROR: #{@title.dbname} :#{ex.message}."
      end
      Gwqa::Doc.remove_connection
    end
    p "renew_docs_section_code 終了:#{Time.now}."
  end

  def self.renew_dsp_admin_name
    p "renew_dsp_admin_name 開始:#{Time.now}."

    title = Gwqa::Control.new
    titles = title.find(:all, :order=> 'id')
    for title in titles
      group = Gwboard::RenewalGroup.find_by_present_group_name(title.dsp_admin_name)
      next if group.blank?

      update_field = "dsp_admin_name='#{group.incoming_group_name}'"
      Gwqa::Control.update_all(update_field, "id='#{title.id}'")
      p "#{title.id}, #{title.create_section}, #{update_field}, #{Time.now}."
    end

    p "renew_dsp_admin_name 終了:#{Time.now}."
  end

  def self.db_alias(item)
    cnn = item.establish_connection
    cnn.spec.config[:database] = @title.dbname.to_s
    Gwboard::CommonDb.establish_connection(cnn.spec.config)
    return item
  end

end
