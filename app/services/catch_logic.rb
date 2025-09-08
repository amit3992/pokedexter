class CatchLogic
  # Returns probability in [0.05, 0.9]
  def self.catch_probability(base_exp)
    # decays as base_exp grows
    p = 0.9 * Math.exp(-base_exp.to_f / 600.0) + 0.05
    p.clamp(0.05, 0.9)
  end
  def self.success?(base_exp)
    rand < catch_probability(base_exp)
  end
end
