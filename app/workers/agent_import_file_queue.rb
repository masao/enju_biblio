class AgentImportFileQueue
  @queue = :agent_import_file

  def self.perform(agent_import_file_id)
    AgentImportFile.find(agent_import_file_id).import_start
  end
end
