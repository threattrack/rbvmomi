class RbVmomi::VIM::ManagedObject
  # Wait for updates on an object until a condition becomes true.
  #
  # @param pathSet [Array] Property paths to wait for updates to.
  # @yield Called when an update to a subscribed property occurs.
  # @yieldreturn [Boolean] Whether to stop waiting.
  #
  # @todo Pass the current property values to the block.
  def wait_until *pathSet, &b
    all = pathSet.empty?
    filter = _connection.propertyCollector.CreateFilter :spec => {
      :propSet => [{ :type => self.class.wsdl_name, :all => all, :pathSet => pathSet }],
      :objectSet => [{ :obj => self }],
    }, :partialUpdates => false
    ver = ''
    counter = 3
    loop do
      sleep counter
      result = _connection.propertyCollector.WaitForUpdates(:version => ver)
      ver = result.version
      counter += 2
      if x = b.call
        return x
      end
    end
  ensure
    filter.DestroyPropertyFilter if filter
  end

  # Efficiently retrieve multiple properties from an object.
  # @param pathSet [Array] Properties to return.
  # @return [Hash] Hash from property paths to values.
  def collect! *pathSet
    spec = {
      :objectSet => [{ :obj => self }],
      :propSet => [{
        :pathSet => pathSet,
        :type => self.class.wsdl_name
      }]
    }
    _connection.propertyCollector.RetrieveProperties(:specSet => [spec])[0].to_hash
  end

  # Efficiently retrieve multiple properties from an object.
  # @param pathSet (see #collect!)
  # @yield [*values] Property values in same order as +pathSet+.
  # @return [Array] Property values in same order as +pathSet+, or the return
  #                 value from the block if it is given.
  def collect *pathSet
    h = collect! *pathSet
    a = pathSet.map { |k| h[k.to_s] }
    if block_given?
      yield a
    else
      a
    end
  end
end
