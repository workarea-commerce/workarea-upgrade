Rails.application.routes.draw do
  mount Weblinc::Core::Engine => '/'
  mount Weblinc::Admin::Engine => '/admin', as: 'admin'
  mount Weblinc::StoreFront::Engine => '/', as: 'store_front'
end
