module CacheHelper
  def with_cache_cleanup
    Rails.cache.clear
    yield

  ensure
    Rails.cache.clear
  end
end
