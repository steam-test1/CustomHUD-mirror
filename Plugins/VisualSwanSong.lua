local _check_bleed_out_original = PlayerDamage._check_bleed_out
local disable_berserker_original = PlayerDamage.disable_berserker

function PlayerDamage:_check_bleed_out(...)
	_check_bleed_out_original(self, ...)
	
	if self._check_berserker_done and not self._berserker_heartbeat then
		managers.environment_controller:set_last_life(true)
		self._berserker_heartbeat = self._unit:sound():play("critical_state_heart_loop")
		SoundDevice:set_rtpc("downed_state_progression", 50)
	end
end

function PlayerDamage:disable_berserker(...)
	if self._berserker_heartbeat then 
		self._berserker_heartbeat:stop()
		self._berserker_heartbeat = nil
		SoundDevice:set_rtpc("downed_state_progression", 0)
	end
	return disable_berserker_original(self, ...)
end
