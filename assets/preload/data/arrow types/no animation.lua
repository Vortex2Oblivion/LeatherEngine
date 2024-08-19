function createPost()
    for i = 0,getUnspawnNotes()-1 do 
		if getUnspawnedNoteNoteType(i) == 'no animation' then 
			setUnspawnedNoteSingAnimPrefix(i, nil)
		end
    end
end