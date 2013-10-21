module DarisHelpers
  def java_memory_model()
    version = `java -version 2>&1`
    if /64-Bit/.match(version) then '64'
    elsif /32-Bit/.match(version) then '32'
    else raise "Cannot figure out jvm memory model from #{version}" end
  end

  def java_memory_max(arg) 
    if arg && arg != '' then
      max = arg.to_i
      if max < 128 then
        raise 'The JVM max memory size is too small'
      end
    else
      # Intuit a sensible max size from the platform and the available memory.
      if java_memory_model() == '32' then
        max = if platform?("windows") then 1500 else 2048 end
      else
        max = (/([0-9]+)kB/.match(node['memory']['total'])[1].to_i / 1024) - 512
      end
    end
    return max
  end
end
