# The same address answers for a window (a request for its Turbo Frame) or for the whole page: a cache, Turbo's prefetch
# included, must keep the two answers apart
module VariesOnTurboFrame
  extend ActiveSupport::Concern

  included do
    after_action :vary_on_turbo_frame
  end

  private

  def vary_on_turbo_frame
    response.headers["Vary"] = [response.headers["Vary"], "Turbo-Frame"].compact.join(", ")
  end
end
