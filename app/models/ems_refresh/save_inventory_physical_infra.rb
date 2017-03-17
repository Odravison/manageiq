#
# Calling order for EmsPhysicalInfra:
# - ems
#   - physical_servers
#

module EmsRefresh::SaveInventoryPhysicalInfra
  def save_ems_physical_infra_inventory(ems, hashes, target = nil)
    target = ems if target.nil?
    log_header = "EMS: [#{ems.name}], id: [#{ems.id}]"

    # Check if the data coming in reflects a complete removal from the ems
    if hashes.blank?
      target.disconnect_inv
      return
    end

    _log.info("#{log_header} Saving EMS Inventory...")
    if debug_trace
      require 'yaml'
      _log.debug "#{log_header} hashes:\n#{YAML.dump(hashes)}"
    end

    child_keys = [
      :physical_servers,
    ]

    # Save and link other subsections
    save_child_inventory(ems, hashes, child_keys, target)

    ems.save!
    hashes[:id] = ems.id

    _log.info("#{log_header} Saving EMS Inventory...Complete")

    ems
  end

  def save_physical_servers_inventory(ems, hashes, target = nil)
    target = ems if target.nil?

    ems.physical_servers.reset
    deletes = if target == ems
                :use_association
              else
                []
              end

    child_keys = [:hardware]

    hashes.each do |h|
      found = PhysicalServer.find_by(:uuid  =>  h[:uuid])
      key_backup = backup_keys(h, child_keys)

      _log.info("Processing #{h[:name]} in #{ems.name}...")
      if found.nil?
        found = ems.physical_servers.build h
      else
        found.update_attributes(h)
      end

      begin
        found.save!
        save_child_inventory(found, key_backup, child_keys)
      rescue ActiveRecord::RecordInvalid
        _log.error("#{log_header} Error when trying to save Physical server")
      end
    end

  end

end
