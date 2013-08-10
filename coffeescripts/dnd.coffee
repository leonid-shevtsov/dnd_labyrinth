$ ->
  $map_container = $('#map_container')
  $activity_log = $('#activity_log')
  $player = $('<div class="player">P</div>')
  $dragon = $('<div class="dragon">D</div>')

  $cells = []
  walls = []
  startI = -1
  startJ = -1
  curI = -1
  curJ = -1
  dragonI = -1
  dragonJ = -1
  treasureI = -1
  treasureJ = -1
  maxSteps = -1
  curSteps = -1
  dragonMode = 'SLEEP'
  treasureFound = false

  for i in [0..7]
    $map_row = $('<div class="map_row"></div>')
    $map_container.append($map_row)
    $cells[i] = []
    for j in [0..7]
      $map_cell = $('<div class="map_cell"></div>')
      $map_row.append($map_cell)
      $map_cell.data('i', i)
      $map_cell.data('j', j)
      $cells[i][j] = $map_cell

  logActivity = (log) ->
    $activity_log.append(log+"\n");

  mode  = 'START'
  logActivity('Place your secret room')


  drawPlayer = () ->
    $cells[curI][curJ].append($player)

  drawDragon = () ->
    $cells[dragonI][dragonJ].append($dragon)

  randomInt = (range) ->
    Math.floor(Math.random()*range)

  adjacent = (i,j, dir) ->
    switch dir
      when 1 then [i-1, j, 4]
      when 2 then [i, j+1, 8]
      when 4 then [i+1, j, 1]
      when 8 then [i, j-1, 2]

  getDirectionForMove = (i1, j1, i2, j2) ->
    for dir in [1, 2, 4, 8]
      adj = adjacent(i1,j1,dir)
      return dir if adj[0]==i2 && adj[1] == j2
    return -1

  validCell = (i,j) ->
    (i>=0) && (i<8) && (j>=0) && (j<8)

  markWall = (i,j, dir) ->
    $cells[i][j].addClass('wall'+dir)

  canMove = (i, j, dir) ->
    [adjI, adjJ, adjDir] = adjacent(i, j, dir)
    canMoveTo(adjI, adjJ, adjDir)

  canMoveTo = (i, j, dir) ->
    validCell(i, j) && (walls[i][j]&dir)==0



  isMapConnected = () ->
    marked = []
    for i in [0..7]
      marked[i] = []
      for j in [0..7]
        marked[i][j] = false
    fillCell = (i, j) ->
      for dir in [1,2,4,8]
        [adjI, adjJ, adjDir] = adjacent(i, j, dir)
        if canMoveTo(adjI, adjJ, adjDir) && !marked[adjI][adjJ]
          marked[adjI][adjJ] = true
          markedCount++
          fillCell(adjI, adjJ)
    marked[0][0] = true
    markedCount = 1
    fillCell(0,0)
    return markedCount == 64


  placeWalls = () ->
    for i in [0..7]
      walls[i] = []
      for j in [0..7]
        walls[i][j] = 0

    allWalls = []
    for i in [0..7]
      for j in [0..6]
        allWalls.push([i, j, 2])
        allWalls.push([j, i, 4])

    count = 0

    # There are 112 inter-cell passages in total
    # Each cell has to connect at least one other for a connected map.
    # This makes for 63 passages (8*8 - 1 for the last cell)
    # This leaves room for exactly 49 walls
    while count<49
      [randomI, randomJ, randomWall] = allWalls.splice(randomInt(allWalls.length), 1)[0]
      [adjI, adjJ, adjWall] = adjacent(randomI, randomJ, randomWall)
      walls[randomI][randomJ] |= randomWall
      walls[adjI][adjJ] |= adjWall
      if isMapConnected()
        # markWall(randomI, randomJ, randomWall)
        # markWall(adjI, adjJ, adjWall)
        count++
      else
        walls[randomI][randomJ] ^= randomWall
        walls[adjI][adjJ] ^= adjWall

  manhattanDistance = (i1,j1,i2,j2) ->
    Math.abs(i1-i2) + Math.abs(j1-j2)

  placeTreasure = () ->
    while true
      treasureI = randomInt(8)
      treasureJ = randomInt(8)
      if manhattanDistance(startI, startJ, treasureI, treasureJ) >= 3
        exits = 0
        for dir in [1, 2, 4, 8]
          exits += 1 if canMove(treasureI, treasureJ, dir)
        if exits>=2
          $cells[treasureI][treasureJ].append('<div class="treasure"></div>')
          dragonMode = 'SLEEP'
          dragonI = treasureI
          dragonJ = treasureJ
          drawDragon()
          return

  dragonClose = () ->
    manhattanDistance(curI, curJ, dragonI, dragonJ) <= 3

  dragonAttack = () ->
    logActivity('DRAGON ATTACKS')
    if treasureFound
      logActivity('DRAGON EATS YOU WITH THE TREASURE. YOU ARE DEFEATED')
      mode='DEFEAT'
    else
      maxSteps-=2
      if maxSteps==2
        logActivity('YOU ARE TOO INJURED TO CONTINUE. YOU ARE DEFEATED')
        mode = 'DEFEAT'
      else
        logActivity('YOU ARE INJURED')
        logActivity('You return to your secret room')
        logActivity('You can now take '+maxSteps+' steps per turn')
        curI = startI
        curJ = startJ
        curSteps = maxSteps
        drawPlayer()


  moveDragon = () ->
    return unless dragonMode == 'AGGRO'
    return if curI==startI && curJ==startJ
    logActivity('THE DRAGON FLIES')
    if dragonI>curI
      dragonI--
    else if dragonI<curI
      dragonI++
    if dragonJ>curJ
      dragonJ--
    else if dragonJ<curJ
      dragonJ++
    drawDragon()
    if dragonI==curI && dragonJ==curJ
      dragonAttack()

  endOfTurn = () ->
    logActivity('End of turn')
    curSteps = maxSteps
    moveDragon()

  $('.map_cell').click ->
    switch mode
      when 'START'
        $(this).append('<div class="secret_room"></div>')
        startI = $(this).data('i')
        startJ = $(this).data('j')
        curI = startI
        curJ = startJ
        maxSteps = 8
        curSteps = maxSteps
        placeWalls()
        placeTreasure()
        mode = 'MOVE'
        logActivity('Move')
        drawPlayer()
      when 'MOVE'
        targetI = $(this).data('i')
        targetJ = $(this).data('j')
        targetDir = getDirectionForMove(curI, curJ, targetI, targetJ)
        if targetDir==-1
          logActivity('You can only move one cell at a time, left, right, up or down')
        else if canMove(curI, curJ, targetDir)
          curI = targetI
          curJ = targetJ
          drawPlayer()
          if dragonClose() && dragonMode=='SLEEP'
            logActivity('THE DRAGON HAS AWAKEN')
            dragonMode = 'AGGRO'
          if curI == dragonI && curJ == dragonJ
            logActivity('YOU HAVE FOUND THE DRAGON')
            dragonAttack()
          else if curI == treasureI && curJ == treasureJ
            logActivity('YOU HAVE FOUND THE TREASURE')
            drawTreasure()
            treasureFound = true
            maxSteps-=2
            endOfTurn()
          else if --curSteps==0
            endOfTurn()

        else
          logActivity('There is a wall in the way')
          # Mark wall on map
          markWall(curI, curJ, targetDir)
          [adjI, adjJ, adjWall] = adjacent(curI, curJ, targetDir)
          markWall(adjI, adjJ, adjWall)
          endOfTurn()