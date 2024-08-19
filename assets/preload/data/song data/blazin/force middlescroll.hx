function generateStaticArrows(){
    if (Options.getData("middlescroll")) return;
    // force middlescroll arrows to generate
    PlayState.instance.generateStaticArrows(50, false);
    PlayState.instance.generateStaticArrows(0.5, true);
}
function createPost(){
    if (Options.getData("middlescroll")) return;
    for (strum in 8...15){ // remove old strums
        PlayState.instance.strumLineNotes.members[strum].kill();
    }
}