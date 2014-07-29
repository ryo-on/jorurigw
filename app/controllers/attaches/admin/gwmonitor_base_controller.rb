# -*- encoding: utf-8 -*-
class Attaches::Admin::GwmonitorBaseController < ApplicationController
  include System::Controller::Scaffold

  def initialize_scaffold
    array_name = params[:controller].split(/\//)
    return if array_name.size != 3
    return if array_name[2].blank?

    params[:system] = array_name[2]

    item = Gwmonitor::Control
    @title = item.find_by_id(params[:title_id])
    return http_error(404) unless @title
  end

  def download
    params[:id] = "#{params[:u_code].to_s}#{params[:d_code].to_s}"
    return http_error(404) if params[:id].blank?

    item = Gwmonitor::BaseFile
    item = item.find_by_id(params[:id])
    return http_error(404) unless item
    return http_error(404) unless params[:name] == sprintf('%08d',Util::CheckDigit.check(item.parent_id))

    chk = request.headers['HTTP_USER_AGENT']
    chk = chk.index("MSIE")
    if chk.blank?
      item_filename = item.filename
    else
      item_filename = item.filename.tosjis
    end

    begin
    f = open(item.f_name)
    if item.is_image
      send_data(f.read, :filename => item_filename, :type => item.content_type, :disposition=>'inline')
    else
      send_data(f.read, :filename => item_filename, :type => item.content_type)
    end
    f.close
    rescue => e
      dump e
      return http_error(404)
    end

  end

end
