PHE_Lyrics = {
    ['Palex_SurgeStreet'] = {
        [0.0] = 'Lyric 1',
        [2] = 'Lyric 2'
        },
    }

    PHE_Lyrics_Macros = {
            ['Palex_SurgeStreet'] = {
            [0.1] = {SetColor = {Color(255, 159, 212)}, SetPeakColor = {Color(255, 0, 170)}},
            [1] = {SetColor = {Color(255, 205, 159), 0}, SetPeakColor = {Color(194, 160, 99), 0}}
            }
    }
if CLIENT then
    
surface.CreateFont('PHE_EMP_Arial', {
font = 'Arial',
size = 96
})


surface.CreateFont('PHE_EMP_Hidden', {
font = 'hidden',
size = 96
})

end
-- Add Custom fonts here to make it easier for you to reference