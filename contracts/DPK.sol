// License-Identifier: MIT
// DontPlayWithKitty.io
pragma solidity 0.8.7;

import "./token/ERC721/ERC721.sol";
import "./token/ERC721/extensions/ERC721Enumerable.sol";
import "./token/ERC721/extensions/ERC721Burnable.sol";
import "./token/ERC721/extensions/ERC721Pausable.sol";
import "./access/Ownable.sol";
import "./access/AccessControl.sol";
import "./utils/Context.sol";
import "./utils/Strings.sol";

/**
 * DontPlayWithKitty.io [ERC-721]
 */
contract DontPlayWithKitty is AccessControl, Ownable, ERC721Enumerable, ERC721Burnable, ERC721Pausable{
    
    using Strings for uint256;
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    string private _baseTokenURI;
    
    mapping (uint256 => mapping(string => string)) private _tokenParamTableMap;
    mapping (uint256 => string[]) private _tokenParamListMap;
    
    mapping (uint256 => uint256) private _tokenTypeCount;
    

    event NFTGenerated(uint256 nft, address owner, uint256 tokenType, string[] params);
    event UpdateTableParams(uint256 tokenId, string key, string value);


    constructor(string memory name, string memory symbol, string memory baseTokenURI) public ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(BURN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, ADMIN_ROLE);
        
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function burn(uint256 tokenId) public virtual override onlyRole(BURN_ROLE) {
        super._burn(tokenId);
    }

    function pause() public virtual onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public virtual onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setBaseTokenURI(string memory _uri)  public virtual onlyRole(ADMIN_ROLE) {
        _baseTokenURI = _uri;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    
    function safeMintFromMap(address to, uint256 tokenType, string[] memory params) public virtual onlyRole(MINTER_ROLE) {
 
        require(params.length % 2 == 0, "params is key|value structure");
        
        _tokenTypeCount[tokenType] += 1;
        
        string memory result = string(abi.encodePacked(tokenType.toString(), _tokenTypeCount[tokenType].toString()));
        
        uint256 tokenId = _string2Uint(result);
        
        _mint(to, tokenId);
        
        _tokenParamListMap[tokenId] = params;
        
        for (uint256 i = 0; i < params.length; i+=2) {
            _setTableParamNoEvent(tokenId, params[i], params[i + 1]);
        }
        
        emit NFTGenerated(tokenId, to, tokenType, params);
    }
    
    function _string2Uint(string memory _str)internal view returns (uint256 res){
        for(uint256 i = 0; i < bytes(_str).length; i++){
            if((uint8(bytes(_str)[i])-48) < 0 || (uint8(bytes(_str)[i])-48) > 9){
                return 0;
            }
            res += (uint8(bytes(_str)[i]) - 48) * 10 ** (bytes(_str).length - i - 1);
        }
        return res;
    }
    
    function setTableParam(uint256 tokenId, string memory key, string memory value) public onlyRole(MINTER_ROLE) {
        _setTableParam(tokenId, key, value);
    }
    
    function _setTableParam(uint256 tokenId, string memory key, string memory value) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        _tokenParamTableMap[tokenId][key] = value;
        emit UpdateTableParams(tokenId, key, value);
    }
    
    function _setTableParamNoEvent(uint256 tokenId, string memory key, string memory value) internal virtual {
        // require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        _tokenParamTableMap[tokenId][key] = value;
    }
    
    function getTableParamByTokenId(uint256 tokenId, string memory key) public view returns (string memory) {
    
        return _tokenParamTableMap[tokenId][key];
    }
    
    function getListParamsByTokenId(uint256 tokenId) public view returns (string[] memory) {
    
        return _tokenParamListMap[tokenId];
    }
    
    function getTypeOfSupply(uint256 tokenType)public view virtual returns(uint256){
        return _tokenTypeCount[tokenType];
    }


    function getOwnerOf(uint256 _id) public view returns(address){
        return ownerOf(_id);
    }
}